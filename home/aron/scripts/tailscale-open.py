#!/usr/bin/env python3
"""Connect Tailscale from a desktop terminal without competing VPN tunnels."""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from urllib.parse import urlsplit


class LaunchError(Exception):
    pass


def run(args, *, timeout=20, check=True):
    """Keep command output private: VPN status and auth errors can contain secrets."""
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        raise LaunchError(f'{args[0]} timed out; inspect its status in a terminal.') from None
    if check and result.returncode:
        # Never echo raw output or arguments containing an authentication URL.
        command = args[2:4] if args[:2] == ['sudo', '-n'] else args[:2]
        label = 'xdg-open' if args[0] == 'xdg-open' else ' '.join(command)
        raise LaunchError(f'{label} failed; inspect its status in a terminal.')
    return result


def read_json(args):
    try:
        return json.loads(run(args).stdout)
    except ValueError:
        raise LaunchError(f'{args[0]} returned invalid JSON; check installed CLI version.') from None


def disconnect_vpns():
    if shutil.which('mullvad'):
        state = read_json(['mullvad', 'status', '--json']).get('state')
        if state != 'disconnected':
            print('Disconnecting Mullvad…')
            run(['mullvad', 'disconnect'])
            for _ in range(10):
                if read_json(['mullvad', 'status', '--json']).get('state') == 'disconnected':
                    break
                time.sleep(1)
            else:
                raise LaunchError('Mullvad did not disconnect; check mullvad status.')
    elif run(['systemctl', 'is-active', '--quiet', 'mullvad-daemon.service'], check=False).returncode == 0:
        raise LaunchError('Mullvad is active but its CLI is missing; install mullvad first.')

    if shutil.which('nmcli'):
        result = run(['nmcli', '-t', '-f', 'UUID,TYPE,DEVICE', 'connection', 'show', '--active'])
        for line in result.stdout.splitlines():
            uuid, kind, device = line.split(':', 2)
            if kind in {'vpn', 'wireguard'} and device != 'tailscale0':
                print('Disconnecting NetworkManager VPN…')
                run(['sudo', '-n', 'nmcli', 'connection', 'down', 'uuid', uuid])
    elif run(['systemctl', 'is-active', '--quiet', 'NetworkManager.service'], check=False).returncode == 0:
        raise LaunchError('NetworkManager is active but nmcli is missing; install nmcli first.')

    units = run(['systemctl', 'list-units', '--type=service', '--state=active', '--no-legend', '--plain']).stdout
    for line in units.splitlines():
        unit = line.split()[0]
        if re.fullmatch(r'(?:wg-quick@|openvpn@|openvpn-client@|openvpn-|wireguard-)[\w@.\\-]+\.service', unit):
            print(f'Stopping VPN service: {unit}')
            run(['sudo', '-n', 'systemctl', 'stop', unit])
            if run(['systemctl', 'is-active', '--quiet', unit], check=False).returncode == 0:
                raise LaunchError(f'{unit} remains active; stop its reconnect policy first.')

    # Never delete unknown interfaces or disable firewall/DNS/kill-switch services.
    tunnels = []
    for link in read_json(['ip', '-j', '-d', 'link', 'show']):
        kind = link.get('linkinfo', {}).get('info_kind')
        if (link['ifname'] != 'tailscale0' and 'UP' in link.get('flags', [])
                and kind in {'tun', 'tap', 'wireguard', 'gre', 'gretap', 'ipip', 'sit', 'vti', 'vti6', 'ip6tnl', 'ip6gre'}):
            tunnels.append(link['ifname'])
    if tunnels:
        raise LaunchError('Active tunnel(s) remain: ' + ', '.join(tunnels)
                          + '. Disconnect them through their VPN app, then retry. No interfaces were deleted.')


def connect():
    run(['sudo', '-n', 'systemctl', 'start', 'tailscaled.service'])
    print('Connecting Tailscale; browser login has a 120-second limit…')
    # Auth output is discarded, not written to logs or temporary files.
    proc = subprocess.Popen(['sudo', '-n', 'tailscale', 'up', '--timeout=120s'],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    opened = set()
    deadline = time.monotonic() + 120
    try:
        while time.monotonic() < deadline:
            status = read_json(['tailscale', 'status', '--json'])
            url = status.get('AuthURL')
            if url and url not in opened:
                parsed = urlsplit(url)
                if (parsed.scheme != 'https' or parsed.hostname != 'login.tailscale.com'
                        or parsed.port not in (None, 443) or parsed.username or parsed.password):
                    raise LaunchError('Unsupported login URL; use sudo tailscale up manually for custom login servers.')
                run(['xdg-open', url], timeout=15)
                opened.add(url)
                print('Browser opened. Complete Tailscale sign-in there.')
            code = proc.poll()
            if code is not None:
                if code != 0:
                    raise LaunchError('tailscale up failed; run sudo tailscale up --timeout=30s in a terminal for diagnostics.')
                if status.get('BackendState') == 'Running':
                    print('Connected: ' + ', '.join(status.get('TailscaleIPs', [])))
                    print('Other VPNs remain disconnected. Reconnecting them may block Tailscale again.')
                    return
            time.sleep(1)
        raise LaunchError('Login timed out after 120 seconds. Check VPN kill-switch settings and Tailscale status, then retry.')
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                # sudo forwards termination to its child; never kill unrelated daemons.
                print('Login process is still stopping; its own 120-second timeout remains active.', file=sys.stderr)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, epilog=(
        'Disconnects supported VPNs; traffic may leave VPN protection. '
        'Run locally as your desktop user. Other VPNs remain disconnected.'))
    parser.parse_args(argv)
    try:
        if os.geteuid() == 0:
            raise LaunchError('Run tailscale-open as your desktop user, not with sudo; browser must not run as root.')
        for name in ('tailscale', 'sudo', 'systemctl', 'ip', 'xdg-open'):
            if not shutil.which(name):
                raise LaunchError(f'Missing dependency: {name}')
        print('VPN connections will be disconnected. Traffic may leave VPN protection. Firewall and DNS settings stay unchanged.')
        # Password prompt is interactive; all later privilege operations are noninteractive.
        result = subprocess.run(['sudo', '-v'], timeout=120)
        if result.returncode:
            raise LaunchError('sudo authorization failed; no VPNs were disconnected.')
        disconnect_vpns()
        connect()
        return 0
    except (LaunchError, OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
        # Malformed external data is not echoed: it can contain auth URLs or private state.
        detail = str(error) if isinstance(error, LaunchError) else 'Command unavailable, timed out, or returned unsupported data.'
        print('Tailscale launcher: ' + detail, file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print('\nCanceled. Disconnected VPNs were not reconnected.', file=sys.stderr)
        return 130


if __name__ == '__main__':
    result = main()
    if result and sys.stdin.isatty():
        try:
            input('Press Enter to close…')
        except (EOFError, KeyboardInterrupt):
            pass
    sys.exit(result)
