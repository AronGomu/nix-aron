"""Static checks for the deployed Pi routing policy; no model calls."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROUTING = ROOT / "dotfiles/agents/skills/_shared/model-routing.md"


class ModelRoutingTests(unittest.TestCase):
    def test_all_task_tiers_have_exact_model_ids(self):
        text = ROUTING.read_text()
        for tier, model in {
            "Luna": "gpt-5.6-luna",
            "Terra": "gpt-5.6-terra",
            "Sol": "gpt-5.6-sol",
            "Astra": "gpt-6-astra",
        }.items():
            self.assertIn(f"**{tier}** = `openai-codex/{model}`", text)

    def test_failure_preserves_effort_and_retry_limit(self):
        text = ROUTING.read_text()
        self.assertIn("Luna → Terra → Sol → Astra", text)
        self.assertIn("Keep the failed attempt's thinking level unchanged", text)
        self.assertIn("At Astra, stay on Astra", text)
        self.assertIn("existing retry limits still apply", text)
        self.assertNotIn("previously failed task", text)

    def test_pi_launch_contract(self):
        text = ROUTING.read_text()
        self.assertIn('"model": "openai-codex/gpt-5.6-luna:medium"', text)
        self.assertIn('`context: "fresh"`', text)
        self.assertIn("new launch", text)
        self.assertIn("not `resume`", text)
        self.assertIn("single, parallel, and chain", text)
        self.assertIn("not hard runtime enforcement", text)

    def test_global_policy_is_deployed_and_loads_routing(self):
        rules = (ROOT / "dotfiles/agents/GLOBAL_RULES.md").read_text()
        self.assertIn("~/.agents/skills/_shared/model-routing.md", rules)
        self.assertIn("takes precedence over skill-local model/thinking defaults", rules)
        deployment = (ROOT / "home/aron/agents.nix").read_text()
        self.assertIn('".pi/agent/APPEND_SYSTEM.md".source = ../../dotfiles/agents/GLOBAL_RULES.md;', deployment)

    def test_review_and_scout_rows_are_present(self):
        rows = re.findall(r"^\| ([^|]+)\|", ROUTING.read_text(), re.MULTILINE)
        tasks = {row.strip() for row in rows}
        self.assertTrue({"Repo scouting / codebase reconnaissance", "Security code review", "Test triage / flaky-test diagnosis"} <= tasks)


if __name__ == "__main__":
    unittest.main()
