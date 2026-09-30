import json
import shutil
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

from click.testing import CliRunner

from migration.cli import cli
from migration.native import NativeDocument, attach, digest
from migration.workflow import load, publish, resume, save
from test_native import fixture


class RecordedCloud:
    """Exercise state transitions locally; never emulate native stroke decoding."""
    def __init__(self, source, initialized, empty):
        self.source = source
        self.initialized = initialized
        self.empty = empty
        self.target = None
        self.uploads = []

    def download(self, source, by_id=True):
        return self.source if source == self.source.id else self.target

    def stat(self, name):
        return {"ID": self.target.id} if self.target else None

    def put(self, path, replace=False):
        self.uploads.append((path, replace))
        self.target = NativeDocument(path) if path.suffix == ".rmdoc" else self.empty


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.cwd() / ".tmp")
        self.directory = Path(self.temp.name)
        self.source = NativeDocument(fixture(self.directory, "source", ["a", "b", "c"], {"b": b"native binary"}, modern=True))
        initialized_path = fixture(self.directory, "target", ["x", "y", "z", "new"])
        self.initialized = NativeDocument(initialized_path)
        empty_path = self.directory / "empty.rmdoc"
        with zipfile.ZipFile(empty_path, "w") as archive:
            for name, data in self.initialized.files.items():
                if name.endswith(".content"):
                    content = json.loads(data)
                    content.pop("formatVersion")
                    content.update(pages=None, redirectionPageMap=None, pageCount=0)
                    data = json.dumps(content).encode()
                archive.writestr(name, data)
        self.cloud = RecordedCloud(self.source, self.initialized, NativeDocument(empty_path))
        shutil.copyfile(initialized_path, self.directory / "target-backup.rmdoc")
        (self.directory / "background.pdf").write_bytes(self.initialized.pdf)
        self.state = {"version": 1, "stage": "prepared", "title": "target", "source_id": "source", "source_hashes": self.source.hashes(), "rmapi": "rmapi", "cutoff": "2026-01-02", "plan": [{"source_index": i, "output_index": i} for i in range(3)] + [{"source_index": None, "output_index": 3}], "background": {"pdf_sha256": digest(self.initialized.pdf), "page_count": 4}}
        save(self.directory, self.state)

    def tearDown(self):
        self.temp.cleanup()

    def test_wait_resume_and_repeat_preserve_strokes_without_duplicate_uploads(self):
        with patch("migration.workflow.Cloud", return_value=self.cloud):
            self.assertEqual(publish(self.directory)["stage"], "awaiting_page_ids")
            self.assertEqual(resume(self.directory)["stage"], "awaiting_page_ids")
            self.assertEqual(len(self.cloud.uploads), 1)
            self.cloud.target = self.initialized
            self.assertEqual(resume(self.directory)["stage"], "complete")
            self.assertEqual(self.cloud.target.files["target/y.rm"], b"native binary")
            self.assertEqual(resume(self.directory)["stage"], "complete")
            self.assertEqual(len(self.cloud.uploads), 2)
            self.assertTrue(load(self.directory)["verification"]["original_files_unchanged"])

    def test_existing_title_is_not_adopted_without_upload_intent(self):
        self.cloud.target = self.initialized
        with patch("migration.workflow.Cloud", return_value=self.cloud), self.assertRaisesRegex(ValueError, "already exists"):
            publish(self.directory)
        self.assertEqual(self.cloud.uploads, [])

    def test_interrupted_publish_adopts_only_the_matching_background(self):
        self.state["stage"] = "publishing"
        save(self.directory, self.state)
        self.cloud.target = self.cloud.empty
        with patch("migration.workflow.Cloud", return_value=self.cloud):
            self.assertEqual(publish(self.directory)["stage"], "awaiting_page_ids")
        self.assertEqual(self.cloud.uploads, [])

    def test_interrupted_native_upload_restores_retained_archive(self):
        prepared = self.directory / "retained.rmdoc"
        attach(self.source, self.initialized, self.state["plan"], prepared)
        self.state.update(stage="attaching", destination_id="target", prepared_archive=prepared.name)
        save(self.directory, self.state)
        with patch("migration.workflow.Cloud", return_value=self.cloud):
            self.assertEqual(resume(self.directory)["stage"], "complete")
        self.assertEqual(len(self.cloud.uploads), 1)
        self.assertFalse(self.cloud.uploads[0][1])

    def test_source_edits_stop_publish(self):
        self.cloud.source.files["source/b.rm"] = b"recent handwriting"
        with patch("migration.workflow.Cloud", return_value=self.cloud), self.assertRaisesRegex(ValueError, "Source changed"):
            publish(self.directory)
        self.assertEqual(self.cloud.uploads, [])

    def test_destination_ink_stops_resume(self):
        self.state.update(stage="awaiting_page_ids", destination_id="target")
        save(self.directory, self.state)
        self.cloud.target = NativeDocument(fixture(self.directory, "target-ink", ["x", "y", "z", "new"], {"y": b"user edits"}))
        self.cloud.target.id = "target"
        self.cloud.target.metadata["visibleName"] = "target"
        self.state["background"]["pdf_sha256"] = digest(self.cloud.target.pdf)
        (self.directory / "background.pdf").write_bytes(self.cloud.target.pdf)
        save(self.directory, self.state)
        with patch("migration.workflow.Cloud", return_value=self.cloud), self.assertRaisesRegex(ValueError, "destination.*ink"):
            resume(self.directory)
        self.assertEqual(self.cloud.uploads, [])

    def test_cli_requires_explicit_source_and_reports_status_without_cloud(self):
        runner = CliRunner()
        result = runner.invoke(cli, ["migration", "prepare", "--from", "2026-01-02", "--title", "new"], env={"AGENT": "0"})
        self.assertNotEqual(result.exit_code, 0)
        self.assertIn("exactly one", result.output)
        with patch("migration.workflow.Cloud") as cloud:
            result = runner.invoke(cli, ["migration", "status", str(self.directory)], env={"AGENT": "1"})
            self.assertEqual(result.exit_code, 0, result.output)
            self.assertEqual(json.loads(result.output)["stage"], "prepared")
            cloud.assert_not_called()


if __name__ == "__main__":
    unittest.main()
