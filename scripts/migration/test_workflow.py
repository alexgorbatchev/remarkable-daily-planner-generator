import copy
import json
import tempfile
import unittest
from pathlib import Path
from uuid import uuid4
from unittest.mock import patch

from click.testing import CliRunner

from migration.cli import cli
from migration.native import NativeDocument, VIEWPORT_FIELDS, digest, prepare_transfer
from migration.workflow import load, publish, resume, save
from test_native import fixture, write_fixture


class RecordedCloud:
    """Exercise resumable orchestration with native archive fixtures."""
    def __init__(self, work, source, initialized, empty):
        self.work, self.source, self.initialized, self.empty = work, source, initialized, empty
        self.target = None
        self.uploads, self.imports, self.settings = [], [], []
        self.fail_import = False
        self.fail_settings = False

    def snapshot(self, document):
        return NativeDocument(write_fixture(self.work / f"{uuid4().hex}.zip", document.id, document.files))

    def persist_content(self, document):
        document.files[f"{document.id}.content"] = json.dumps(document.content).encode()

    def download(self, source, by_id=True):
        return self.snapshot(self.source if source == self.source.id else self.target)

    def stat(self, name):
        return {"ID": self.target.id} if self.target else None

    def upload(self, path, title, evidence):
        self.uploads.append(path)
        self.target = self.snapshot(self.empty)
        evidence.write_text(json.dumps({"version": 1, "title": title, "folder": "", "pages": 4, "result": {"id": self.target.id}, "files": [{"name": name, "sha256": digest(data), "size": len(data)} for name, data in self.target.files.items()]}))
        return {"state": "verified", "document_id": self.target.id}

    def upload_check(self, evidence):
        return {"state": "verified", "document_id": self.target.id}

    def import_strokes(self, destination, mapping):
        self.imports.append(destination)
        for row in json.loads(mapping.read_text()):
            data = (mapping.parent / row["source"]).read_bytes()
            self.target.files[f"{destination}/{self.target.pages[row['page']]}.rm"] = data
        self.target = self.snapshot(self.target)
        if self.fail_import:
            self.fail_import = False
            raise RuntimeError("Import commit response lost")
        return {"state": "verified"}

    def transfer_settings(self, source, destination, mapping):
        self.settings.append(destination)
        indexes = {r["source_page"]: r["destination_page"] for r in json.loads(mapping.read_text())}
        ids = {self.source.pages[i]: self.target.pages[o] for i, o in indexes.items()}
        self.target.content["pageTags"] = [{**t, "pageId": ids[t["pageId"]]} for t in self.source.content.get("pageTags", [])]
        self.target.content["tags"] = copy.deepcopy(self.source.content.get("tags", []))
        for key in VIEWPORT_FIELDS:
            if key in self.source.content:
                self.target.content[key] = self.source.content[key]
            else:
                self.target.content.pop(key, None)
        self.persist_content(self.target)
        self.target = self.snapshot(self.target)
        if self.fail_settings:
            self.fail_settings = False
            raise RuntimeError("Settings commit response lost")
        return {"state": "verified"}


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.cwd() / ".tmp")
        self.directory = Path(self.temp.name)
        self.source = NativeDocument(fixture(self.directory, str(uuid4()), ["a", "b", "c"], {"b": b"native binary"}, modern=True))
        self.source.content["pageTags"] = [{"name": "work", "pageId": "b", "timestamp": 12}]
        self.source.files[f"{self.source.id}.content"] = json.dumps(self.source.content).encode()
        self.initialized = NativeDocument(fixture(self.directory, str(uuid4()), ["x", "y", "z", "new"]))
        self.initialized.metadata["visibleName"] = "target"
        self.initialized.content["zoomMode"] = "bestFit"
        self.initialized.files[f"{self.initialized.id}.metadata"] = json.dumps(self.initialized.metadata).encode()
        self.initialized.files[f"{self.initialized.id}.content"] = json.dumps(self.initialized.content).encode()
        self.initialized = NativeDocument(write_fixture(self.directory / "initialized.zip", self.initialized.id, self.initialized.files))
        files = dict(self.initialized.files)
        content = json.loads(files[f"{self.initialized.id}.content"])
        content["pages"] = None
        content.pop("redirectionPageMap")
        files[f"{self.initialized.id}.content"] = json.dumps(content).encode()
        empty = NativeDocument(write_fixture(self.directory / "empty.zip", self.initialized.id, files))
        self.cloud = RecordedCloud(self.directory, self.source, self.initialized, empty)
        (self.directory / "background.pdf").write_bytes(self.initialized.pdf)
        self.state = {"version": 2, "stage": "prepared", "title": "target", "source_id": self.source.id, "source_hashes": self.source.hashes(), "remarkable": "remarkable", "cutoff": "2026-01-02", "plan": [{"source_index": i, "output_index": i} for i in range(3)] + [{"source_index": None, "output_index": 3}], "background": {"pdf_sha256": digest(self.initialized.pdf), "page_count": 4}}
        save(self.directory, self.state)

    def tearDown(self):
        self.temp.cleanup()

    def start_initialized(self):
        publish(self.directory)
        self.cloud.target = self.cloud.snapshot(self.initialized)

    def test_wait_resume_repeat_preserve_strokes_and_settings_without_duplicate_writes(self):
        with patch("migration.workflow.Cloud", return_value=self.cloud):
            self.assertEqual(publish(self.directory)["stage"], "awaiting_page_ids")
            self.assertEqual(resume(self.directory)["stage"], "awaiting_page_ids")
            self.cloud.target = self.cloud.snapshot(self.initialized)
            self.assertEqual(resume(self.directory)["stage"], "complete")
            self.assertEqual(self.cloud.target.files[f"{self.initialized.id}/y.rm"], b"native binary")
            self.assertEqual(self.cloud.target.content["pageTags"][0]["pageId"], "y")
            self.assertEqual(self.cloud.target.content["zoomMode"], "fitToHeight")
            self.assertEqual(resume(self.directory)["stage"], "complete")
        self.assertEqual((len(self.cloud.uploads), len(self.cloud.imports), len(self.cloud.settings)), (1, 1, 1))
        self.assertTrue(load(self.directory)["verification"]["original_files_unchanged"])

    def test_existing_title_is_not_adopted_without_upload_intent(self):
        self.cloud.target = self.initialized
        with patch("migration.workflow.Cloud", return_value=self.cloud), self.assertRaisesRegex(ValueError, "already exists"):
            publish(self.directory)
        self.assertEqual(self.cloud.uploads, [])

    def test_uncertain_upload_uses_saved_uuid_without_creating_another_copy(self):
        self.cloud.upload(self.directory / "background.pdf", "target", self.directory / "upload.json")
        self.state["stage"] = "publishing"
        save(self.directory, self.state)
        with patch("migration.workflow.Cloud", return_value=self.cloud):
            self.assertEqual(publish(self.directory)["destination_id"], self.initialized.id)
        self.assertEqual(len(self.cloud.uploads), 1)

    def test_initialized_upload_recovers_by_identity_when_creation_hash_changed(self):
        self.cloud.upload(self.directory / "background.pdf", "target", self.directory / "upload.json")
        self.cloud.target = self.initialized
        self.state["stage"] = "publishing"
        save(self.directory, self.state)
        with patch("migration.workflow.Cloud", return_value=self.cloud), patch.object(self.cloud, "upload_check", side_effect=RuntimeError("creation hash changed")):
            self.assertEqual(publish(self.directory)["stage"], "awaiting_page_ids")
        self.assertEqual(len(self.cloud.uploads), 1)

    def test_committed_import_error_recovers_without_reimporting(self):
        with patch("migration.workflow.Cloud", return_value=self.cloud):
            self.start_initialized()
            self.cloud.fail_import = True
            with self.assertRaisesRegex(RuntimeError, "response lost"):
                resume(self.directory)
            self.assertEqual(load(self.directory)["stage"], "importing")
            self.assertEqual(resume(self.directory)["stage"], "complete")
        self.assertEqual(len(self.cloud.imports), 1)

    def test_committed_settings_error_recovers_without_rewriting(self):
        with patch("migration.workflow.Cloud", return_value=self.cloud):
            self.start_initialized()
            self.cloud.fail_settings = True
            with self.assertRaisesRegex(RuntimeError, "response lost"):
                resume(self.directory)
            self.assertEqual(load(self.directory)["stage"], "settings")
            self.assertEqual(resume(self.directory)["stage"], "complete")
        self.assertEqual(len(self.cloud.settings), 1)

    def test_source_edits_stop_publish(self):
        changed = {f"{self.source.id}/b.rm": b"recent handwriting", f"{self.source.id}.metadata": json.dumps({**self.source.metadata, "lastOpenedPage": 1}).encode()}
        for name, data in changed.items():
            with self.subTest(attachment=name):
                original = self.cloud.source.files[name]
                self.cloud.source.files[name] = data
                try:
                    with patch("migration.workflow.Cloud", return_value=self.cloud), self.assertRaisesRegex(ValueError, "Source changed"):
                        publish(self.directory)
                finally:
                    self.cloud.source.files[name] = original
        self.assertEqual(self.cloud.uploads, [])

    def test_destination_ink_stops_resume(self):
        with patch("migration.workflow.Cloud", return_value=self.cloud):
            self.start_initialized()
            self.cloud.target.files[f"{self.initialized.id}/y.rm"] = b"user edits"
            self.cloud.target = self.cloud.snapshot(self.cloud.target)
            with self.assertRaisesRegex(ValueError, "destination.*ink"):
                resume(self.directory)
        self.assertEqual(self.cloud.imports, [])

    def test_partial_import_stops_without_overwriting(self):
        with patch("migration.workflow.Cloud", return_value=self.cloud):
            self.start_initialized()
            self.cloud.fail_import = True
            with self.assertRaises(RuntimeError):
                resume(self.directory)
            self.cloud.target.files[f"{self.initialized.id}/y.rm"] = b"partial or edited bytes"
            self.cloud.target = self.cloud.snapshot(self.cloud.target)
            with self.assertRaisesRegex(ValueError, "stroke"):
                resume(self.directory)
        self.assertEqual(len(self.cloud.imports), 1)

    def test_unrelated_destination_edit_stops_before_settings_write(self):
        with patch("migration.workflow.Cloud", return_value=self.cloud):
            self.start_initialized()
            self.cloud.fail_import = True
            with self.assertRaises(RuntimeError):
                resume(self.directory)
            self.cloud.target.files[f"{self.initialized.id}.pagedata"] = b"changed template"
            self.cloud.target = self.cloud.snapshot(self.cloud.target)
            with self.assertRaisesRegex(ValueError, "attachment changed"):
                resume(self.directory)
        self.assertEqual(self.cloud.settings, [])

    def test_cli_requires_source_and_reports_status_without_cloud(self):
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
