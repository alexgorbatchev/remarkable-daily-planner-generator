import json
import tempfile
import unittest
import zipfile
from pathlib import Path

import pymupdf

from migration.native import NativeDocument, digest, prepare_transfer, verify_attachment
from migration.background import inventory, plan_pages


def write_fixture(path, document_id, files):
    manifest = b"native manifest fixture"
    snapshot = {"format_version": 1, "document_id": document_id, "document_hash": "fixture", "root": {"hash": "fixture", "generation": 1, "schemaVersion": 3}, "manifest_sha256": digest(manifest), "files": [{"name": name, "hash": digest(data), "sha256": digest(data), "size": len(data)} for name, data in files.items()]}
    with zipfile.ZipFile(path, "w") as archive:
        for name, data in files.items():
            archive.writestr("files/" + name, data)
        archive.writestr("evidence/document.docSchema", manifest)
        archive.writestr("evidence/snapshot.json", json.dumps(snapshot))
    return path


def fixture(directory, document_id, ids, strokes=None, modern=False):
    pdf = pymupdf.open()
    for index in range(len(ids)):
        page = pdf.new_page(width=448, height=595)
        if index == 0:
            page.insert_text((180, 50), "2026", fontsize=18)
            page.insert_text((30, 90), "January 2026 February 2026")
        else:
            day = 1 + (index - 1) % 2
            page.insert_text((20, 40), f"2026 Jan {day:02d}")
            if index <= 2:
                page.insert_text((20, 70), "Top Priority")
            else:
                page.insert_text((300, 40), "Day")
    content = {"formatVersion": 2 if modern else 1, "pageCount": len(ids), "fileType": "pdf", "pageTags": [], "tags": [], "zoomMode": "fitToHeight", "viewBackgroundFilter": "off"}
    if modern:
        content["cPages"] = {"pages": [{"id": page_id, "idx": {"value": str(index)}, "redir": {"value": index}} for index, page_id in enumerate(ids)]}
    else:
        content.update(pages=ids, redirectionPageMap=list(range(len(ids))))
    files = {f"{document_id}.content": json.dumps(content).encode(), f"{document_id}.metadata": json.dumps({"visibleName": document_id, "parent": "", "type": "DocumentType"}).encode(), f"{document_id}.pdf": pdf.tobytes(), f"{document_id}.pagedata": ("Blank\n" * len(ids)).encode()}
    files.update({f"{document_id}/{page_id}.rm": data for page_id, data in (strokes or {}).items()})
    return write_fixture(directory / f"{document_id}.zip", document_id, files)


class NativeMigrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.cwd() / ".tmp")
        self.directory = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def test_prepares_native_bytes_and_explicit_import_and_settings_maps(self):
        source = NativeDocument(fixture(self.directory, "source", ["a", "b", "c"], {"b": b"\x00\xffnative bytes"}, modern=True))
        source.content["pageTags"] = [{"name": "work", "pageId": "b", "timestamp": 1}]
        target = NativeDocument(fixture(self.directory, "target", ["x", "y", "z"]))
        target.content["zoomMode"] = "bestFit"
        mapping = [{"source_index": i, "output_index": i} for i in range(3)]
        directory = self.directory / "transfer"
        directory.mkdir()
        records = prepare_transfer(source, target, mapping, directory)
        imports = json.loads((directory / "import-map.json").read_text())
        self.assertEqual((directory / imports[0]["source"]).read_bytes(), source.files["source/b.rm"])
        self.assertEqual(imports[0]["page"], 1)
        self.assertEqual(json.loads((directory / "settings-map.json").read_text()), [{"source_page": i, "destination_page": i} for i in range(3)])
        self.assertEqual(target.content["zoomMode"], "bestFit")
        self.assertEqual(target.strokes, {})
        self.assertEqual(records[0]["output_index"], 1)

    def test_detects_corrupted_native_bytes(self):
        source = NativeDocument(fixture(self.directory, "source", ["a", "b"], {"b": b"binary ink"}))
        target = NativeDocument(fixture(self.directory, "target", ["x", "y"], {"y": b"corrupted"}))
        with self.assertRaisesRegex(ValueError, "stroke"):
            verify_attachment(source, target, [{"source_index": i, "output_index": i} for i in range(2)])

    def test_tag_verification_retains_unmapped_tags_and_rejects_changed_payload_or_order(self):
        source = NativeDocument(fixture(self.directory, "source", ["a", "b"], {"b": b"ink"}))
        source.content["tags"] = [{"name": "document", "timestamp": 10}]
        source.content["pageTags"] = [{"name": name, "pageId": "b", "timestamp": 12, "extra": {"keep": True}} for name in ("first", "second")]
        baseline = NativeDocument(fixture(self.directory, "target", ["x", "y", "new"]))
        baseline.content["pageTags"] = [{"name": "retained", "pageId": "new", "timestamp": 15}]
        baseline.files["target.content"] = json.dumps(baseline.content).encode()
        files = {**baseline.files, "target/y.rm": b"ink"}
        target = NativeDocument(write_fixture(self.directory / "transferred.zip", "target", files))
        mapping = [{"source_index": i, "output_index": i} for i in range(2)]
        remapped = [{**tag, "pageId": "y"} for tag in source.content["pageTags"]]
        target.content["tags"] = source.content["tags"]
        target.content["pageTags"] = remapped
        with self.assertRaisesRegex(ValueError, "tags"):
            verify_attachment(source, target, mapping, baseline)
        target.content["pageTags"] = remapped[::-1] + baseline.content["pageTags"]
        with self.assertRaisesRegex(ValueError, "tags"):
            verify_attachment(source, target, mapping, baseline)
        target.content["pageTags"] = remapped + baseline.content["pageTags"]
        self.assertEqual(verify_attachment(source, target, mapping, baseline)["status"], "PASS")
        target.content["tags"] = [{"name": "document", "timestamp": 11}]
        with self.assertRaisesRegex(ValueError, "tags"):
            verify_attachment(source, target, mapping, baseline)

    def test_rejects_target_ink_and_incomplete_mapping(self):
        source = NativeDocument(fixture(self.directory, "source", ["a", "b"], {"b": b"ink"}))
        target = NativeDocument(fixture(self.directory, "target", ["x", "y"], {"y": b"new ink"}))
        with self.assertRaisesRegex(ValueError, "destination.*ink"):
            prepare_transfer(source, target, [{"source_index": i, "output_index": i} for i in range(2)], self.directory)
        clean = NativeDocument(fixture(self.directory, "clean", ["x", "y"]))
        with self.assertRaisesRegex(ValueError, "mapping"):
            prepare_transfer(source, clean, [{"source_index": 0, "output_index": 0}], self.directory)

    def test_rejects_unknown_native_pages(self):
        path = fixture(self.directory, "source", ["a"], {"unknown": b"ink"})
        with self.assertRaisesRegex(ValueError, "unmapped"):
            NativeDocument(path)

    def test_rejects_reordered_native_pages_before_building(self):
        path = fixture(self.directory, "source", ["a", "b"])
        files = NativeDocument(path).files
        content = json.loads(files["source.content"])
        content["redirectionPageMap"] = [1, 0]
        files["source.content"] = json.dumps(content).encode()
        write_fixture(path, "source", files)
        with self.assertRaisesRegex(ValueError, "Reordered"):
            NativeDocument(path)

    def test_archive_evidence_rejects_corrupted_native_bytes(self):
        path = fixture(self.directory, "source", ["a"], {"a": b"native"})
        with zipfile.ZipFile(path) as archive:
            files = {name: archive.read(name) for name in archive.namelist()}
        files["files/source/a.rm"] = b"corrupted"
        with zipfile.ZipFile(path, "w") as archive:
            for name, data in files.items():
                archive.writestr(name, data)
        with self.assertRaisesRegex(ValueError, "hash|evidence"):
            NativeDocument(path)

    def test_archive_without_remarkable_snapshot_evidence_has_actionable_error(self):
        document = NativeDocument(fixture(self.directory, "source", ["a"]))
        path = self.directory / "legacy.zip"
        with zipfile.ZipFile(path, "w") as archive:
            for name, data in document.files.items():
                archive.writestr(name, data)
        with self.assertRaisesRegex(ValueError, "remarkable doc archive"):
            NativeDocument(path)

    def test_inventory_and_repeat_plan_do_not_duplicate_standups(self):
        source = NativeDocument(fixture(self.directory, "source", ["a", "b", "c", "d", "e"]))
        pages = inventory(source, 2026)
        self.assertEqual([(p["kind"], p["date"]) for p in pages], [("calendar", None), ("day", "2026-01-01"), ("day", "2026-01-02"), ("notes", "2026-01-01"), ("notes", "2026-01-02")])
        first = plan_pages(pages, "2026-01-02", True)
        self.assertEqual(len(first), 6)
        self.assertEqual(first[-1]["kind"], "standup")
        second = plan_pages(first, "2026-01-02", True)
        self.assertEqual(len(second), 6)
        self.assertEqual([p["output_index"] for p in second], list(range(6)))


if __name__ == "__main__":
    unittest.main()
