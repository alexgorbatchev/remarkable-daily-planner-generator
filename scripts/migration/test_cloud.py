import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from click.testing import CliRunner

from migration.cli import cli
from migration.cloud import Cloud
from migration.native import NativeDocument
from test_native import fixture


class CloudCommandTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.cwd() / ".tmp")
        self.work = Path(self.temp.name)
        self.cloud = Cloud("remarkable", self.work)

    def tearDown(self):
        self.temp.cleanup()

    def test_documented_commands_use_remarkable_agent_mode_and_fresh_reads(self):
        calls = []
        source = fixture(self.work, "source", ["a"])

        def run(command, **options):
            calls.append(command)
            self.assertEqual(options["env"]["AGENT"], "1")
            self.assertEqual(options["env"]["TMPDIR"], str(self.work / "remarkable-temp"))
            self.assertEqual(command[0], "remarkable")
            self.assertEqual(command[-1], "--no-cache")
            if command[1:3] == ["doc", "archive"]:
                Path(command[command.index("--output") + 1]).write_bytes(source.read_bytes())
            return subprocess.CompletedProcess(command, 0, "state: verified\ndocument_id: source\n", "")

        with patch("migration.cloud.subprocess.run", side_effect=run):
            self.assertEqual(self.cloud.download("source").id, "source")
            self.cloud.upload(self.work / "pdf", "title", self.work / "upload.json")
            self.cloud.upload_check(self.work / "upload.json")
            self.cloud.import_strokes("destination", self.work / "import-map.json")
            self.cloud.transfer_settings("source", "destination", self.work / "settings-map.json")
        self.assertEqual([c[2] for c in calls], ["archive", "upload", "upload-check", "import", "settings"])
        self.assertEqual(calls[-1][3:6], ["transfer", "source", "destination"])
        self.assertIn("--replace-viewport", calls[-1])
        logs = list(self.work.glob("remarkable-*.json"))
        self.assertEqual(len(logs), len(calls))
        self.assertTrue(all(json.loads(p.read_text())["exit_status"] == 0 for p in logs))

    def test_title_lookup_matches_exactly_and_rejects_ambiguity(self):
        output = "ID\tNAME\tTYPE\tMODIFIED\na\ttarget extra\tDocumentType\t1\nb\ttarget\tDocumentType\t2\n"
        with patch.object(self.cloud, "command", return_value=output):
            self.assertEqual(self.cloud.stat("target")["ID"], "b")
            self.assertIsNone(self.cloud.stat("absent"))
        output += "c\ttarget\tDocumentType\t3\n"
        with patch.object(self.cloud, "command", return_value=output), self.assertRaisesRegex(ValueError, "ambiguous"):
            self.cloud.stat("target")

    def test_partial_state_is_an_error_and_is_logged_without_retrying(self):
        result = subprocess.CompletedProcess([], 1, "state: commit-unknown\n", "connection closed")
        with patch("migration.cloud.subprocess.run", return_value=result) as run, self.assertRaisesRegex(RuntimeError, "saved evidence"):
            self.cloud.import_strokes("destination", self.work / "map.json")
        self.assertEqual(run.call_count, 1)
        log = json.loads(next(self.work.glob("remarkable-*.json")).read_text())
        self.assertEqual(log["exit_status"], 1)
        self.assertIn("commit-unknown", log["stdout"])

    def test_zero_exit_without_verified_state_is_rejected(self):
        with patch.object(self.cloud, "command", return_value="state: committed\n"), self.assertRaisesRegex(ValueError, "verified"):
            self.cloud.upload_check(self.work / "upload.json")

    def test_timeout_retains_partial_commit_output_without_retrying(self):
        error = subprocess.TimeoutExpired(["remarkable"], 330, output=b"state: committed\n", stderr=b"verification interrupted\n")
        with patch("migration.cloud.subprocess.run", side_effect=error) as run, self.assertRaisesRegex(RuntimeError, "saved evidence"):
            self.cloud.import_strokes("destination", self.work / "map.json")
        self.assertEqual(run.call_count, 1)
        log = json.loads(next(self.work.glob("remarkable-*.json")).read_text())
        self.assertEqual(log["stdout"], "state: committed\n")
        self.assertEqual(log["stderr"], "verification interrupted\n")
        self.assertTrue(log["timeout"])

    def test_removed_client_option_is_not_accepted(self):
        result = CliRunner().invoke(cli, ["migration", "prepare", "--rmapi", "unapproved"])
        self.assertNotEqual(result.exit_code, 0)
        self.assertIn("No such option", result.output)
