"""Managed Pi ADHD package/default regression checks; no network or live writes."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / ("config" if (ROOT / "config/pi").is_dir() else "dotfiles")
PACKAGE = "git:github.com/ayghri/i-have-adhd@24d22f783e57cb73c957848b588c6f651b6f9cd8"


class PiAdhdConfig(unittest.TestCase):
    def test_reviewed_package_installed_once_without_disabling_resources(self):
        settings = json.loads((SOURCE / "pi/agent/settings.json").read_text())
        matches = [p for p in settings["packages"]
                   if "ayghri/i-have-adhd" in (p if isinstance(p, str) else p["source"])]
        self.assertEqual(matches, [{"source": PACKAGE}])

    def test_new_sessions_default_on_with_visible_status(self):
        path = SOURCE / "pi/agent/i-have-adhd.json"
        self.assertTrue(path.is_file(), "Pi ADHD defaults missing")
        self.assertEqual(json.loads(path.read_text()), {"alwaysOn": True, "hideStatus": False})

    def test_caveman_default_preserved(self):
        config = json.loads((SOURCE / "pi/agent/configs/caveman.json").read_text())
        self.assertEqual(config["defaultLevel"], "ultra")


if __name__ == "__main__":
    unittest.main()
