"""Offline launcher tests: no network, privilege escalation, or browser launch."""
import contextlib
import io
import json
from pathlib import Path
import runpy
import subprocess
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'bin/tailscale-open'
if not SCRIPT.exists():
    SCRIPT = ROOT / 'home/aron/scripts/tailscale-open.py'


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.module = runpy.run_path(str(SCRIPT))
        self.calls = []
        self.nm = ''
        self.units = ''
        self.links = []
        self.mullvad = 'disconnected'
        self.auth = ''
        self.state = 'Running'
        self.fail = None
        self.proc = unittest.mock.Mock()
        self.proc.poll.return_value = 0
        self.proc.wait.return_value = 0

    def command(self, args, **kwargs):
        self.calls.append(args)
        key = args[2:] if args[:2] == ['sudo', '-n'] else args
        if self.fail and self.fail in key:
            return subprocess.CompletedProcess(args, 1, '', 'private diagnostic')
        output = ''
        if key == ['mullvad', 'status', '--json']:
            output = json.dumps({'state': self.mullvad})
        elif key == ['mullvad', 'disconnect']:
            self.mullvad = 'disconnected'
        elif key[:2] == ['nmcli', '-t']:
            output = self.nm
        elif key[:3] == ['nmcli', 'connection', 'down']:
            self.nm = ''
        elif key[:2] == ['systemctl', 'list-units']:
            output = self.units
        elif key[:2] == ['systemctl', 'is-active']:
            return subprocess.CompletedProcess(args, 3, '', '')
        elif key[:2] == ['ip', '-j']:
            output = json.dumps(self.links)
        elif key == ['tailscale', 'status', '--json']:
            output = json.dumps({'BackendState': self.state, 'AuthURL': self.auth,
                                 'TailscaleIPs': ['100.64.0.2']})
        elif key[0] == 'xdg-open':
            self.auth = ''
            self.state = 'Running'
            self.proc.poll.return_value = 0
        return subprocess.CompletedProcess(args, 0, output, '')

    def launch(self, missing=None, uid=1000):
        output = io.StringIO()
        with patch('subprocess.run', side_effect=self.command), \
             patch('subprocess.Popen', return_value=self.proc) as popen, \
             patch('shutil.which', side_effect=lambda name: None if name == missing else '/mock/' + name), \
             patch('os.geteuid', return_value=uid), \
             patch('time.sleep'), contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            code = self.module['main']([])
        return code, output.getvalue(), popen

    def test_help_never_mutates_network(self):
        with patch('subprocess.run') as command, contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(SystemExit) as result:
                self.module['main'](['--help'])
            self.assertEqual(result.exception.code, 0)
            command.assert_not_called()

    def test_unknown_arguments_never_mutate_network(self):
        with patch('subprocess.run') as command, contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as result:
                self.module['main'](['--unsupported'])
            self.assertEqual(result.exception.code, 2)
            command.assert_not_called()

    def test_already_logged_in_connects_without_browser(self):
        code, output, popen = self.launch()
        self.assertEqual(code, 0, output)
        self.assertIn('100.64.0.2', output)
        self.assertFalse(any(c[0] == 'xdg-open' for c in self.calls))
        self.assertIn('--timeout=120s', popen.call_args.args[0])

    def test_disconnects_mullvad_nm_and_known_services(self):
        self.mullvad = 'connected'
        self.nm = 'vpn-id:vpn:tun0\nwg-id:wireguard:wg0\nts-id:tun:tailscale0\nlan:ethernet:eth0\n'
        self.units = 'openvpn-client@work.service loaded active running VPN\nwg-quick@work.service loaded active running VPN\nsshd.service loaded active running SSH\n'
        code, output, _ = self.launch()
        self.assertEqual(code, 0, output)
        self.assertIn(['mullvad', 'disconnect'], self.calls)
        self.assertIn(['sudo', '-n', 'nmcli', 'connection', 'down', 'uuid', 'vpn-id'], self.calls)
        self.assertIn(['sudo', '-n', 'systemctl', 'stop', 'wg-quick@work.service'], self.calls)
        self.assertFalse(any('sshd.service' in c or 'lan' in c or 'ts-id' in c for c in self.calls))

    def test_failed_disconnect_stops_before_tailscale(self):
        self.mullvad = 'connected'
        self.fail = 'disconnect'
        code, output, popen = self.launch()
        self.assertEqual(code, 1)
        self.assertIn('disconnect failed', output)
        self.assertNotIn('private diagnostic', output)
        popen.assert_not_called()

    def test_unknown_tunnel_blocks_without_deleting_interface(self):
        self.links = [{'ifname': 'tun9', 'flags': ['UP'], 'linkinfo': {'info_kind': 'tun'}}]
        code, output, popen = self.launch()
        self.assertEqual(code, 1)
        self.assertIn('tun9', output)
        popen.assert_not_called()
        self.assertFalse(any('delete' in c for c in self.calls))

    def test_tailscale_and_down_tunnels_are_preserved(self):
        self.links = [{'ifname': 'tailscale0', 'flags': ['UP'], 'linkinfo': {'info_kind': 'tun'}},
                      {'ifname': 'wg9', 'flags': [], 'linkinfo': {'info_kind': 'wireguard'}}]
        self.assertEqual(self.launch()[0], 0)

    def test_missing_dependency_fails_before_mutation(self):
        code, output, popen = self.launch(missing='tailscale')
        self.assertEqual(code, 1)
        self.assertIn('Missing dependency: tailscale', output)
        self.assertEqual(self.calls, [])
        popen.assert_not_called()

    def test_browser_login_as_user_no_url_in_output(self):
        self.state = 'NeedsLogin'
        self.auth = 'https://login.tailscale.com/a/mock-login'
        self.proc.poll.return_value = None
        code, output, _ = self.launch()
        self.assertEqual(code, 0, output)
        self.assertIn(['xdg-open', 'https://login.tailscale.com/a/mock-login'], self.calls)
        self.assertNotIn('mock-login', output)

    def test_browser_failure_is_visible_and_stops_login(self):
        self.state = 'NeedsLogin'
        self.auth = 'https://login.tailscale.com/a/mock-login'
        self.proc.poll.return_value = None
        self.fail = 'xdg-open'
        code, output, _ = self.launch()
        self.assertEqual(code, 1)
        self.assertIn('xdg-open failed', output)
        self.assertNotIn('mock-login', output)
        self.proc.terminate.assert_called_once()

    def test_untrusted_login_url_is_not_opened(self):
        self.auth = 'https://untrusted.invalid/a/mock-login'
        self.state = 'NeedsLogin'
        self.proc.poll.return_value = None
        code, output, _ = self.launch()
        self.assertEqual(code, 1)
        self.assertIn('Unsupported login URL', output)
        self.assertFalse(any(c[0] == 'xdg-open' for c in self.calls))

    def test_login_timeout_is_bounded(self):
        self.state = 'NeedsLogin'
        self.proc.poll.return_value = None
        with patch('time.monotonic', side_effect=[0, 0, 121]):
            code, output, _ = self.launch()
        self.assertEqual(code, 1)
        self.assertIn('Login timed out', output)
        self.proc.terminate.assert_called_once()

    def test_root_launch_is_rejected_before_mutation(self):
        code, output, popen = self.launch(uid=0)
        self.assertEqual(code, 1)
        self.assertIn('not with sudo', output)
        self.assertEqual(self.calls, [])
        popen.assert_not_called()

    def test_sudo_failure_leaves_vpns_untouched(self):
        self.fail = '-v'
        code, output, popen = self.launch()
        self.assertEqual(code, 1)
        self.assertIn('sudo authorization failed', output)
        self.assertEqual(self.calls, [['sudo', '-v']])
        popen.assert_not_called()

    def test_failed_service_stop_prevents_tailscale_start(self):
        self.units = 'openvpn-work.service loaded active running VPN\n'
        self.fail = 'stop'
        code, output, popen = self.launch()
        self.assertEqual(code, 1)
        self.assertIn('systemctl stop failed', output)
        popen.assert_not_called()

    def test_status_command_failure_stops_login_without_private_output(self):
        self.fail = 'tailscale'
        self.proc.poll.return_value = None
        code, output, _ = self.launch()
        self.assertEqual(code, 1)
        self.assertIn('tailscale status failed', output)
        self.assertNotIn('private diagnostic', output)
        self.proc.terminate.assert_called_once()

    def test_nm_failure_prevents_tailscale_start(self):
        self.nm = 'vpn-id:vpn:tun0\n'
        self.fail = 'down'
        code, output, popen = self.launch()
        self.assertEqual(code, 1)
        self.assertIn('nmcli connection failed', output)
        popen.assert_not_called()

    def test_failed_up_is_not_reported_connected(self):
        self.proc.poll.return_value = 1
        code, output, _ = self.launch()
        self.assertEqual(code, 1)
        self.assertIn('tailscale up failed', output)
        self.assertNotIn('Connected:', output)


if __name__ == '__main__':
    unittest.main()
