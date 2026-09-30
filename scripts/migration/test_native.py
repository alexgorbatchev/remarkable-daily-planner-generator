import json
import tempfile
import unittest
import zipfile
from pathlib import Path

import pymupdf

from migration.native import NativeDocument, attach, verify_attachment
from migration.background import inventory, plan_pages


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
    path = directory / f"{document_id}.rmdoc"
    with zipfile.ZipFile(path, "w") as archive:
        archive.writestr(f"{document_id}.content", json.dumps(content))
        archive.writestr(f"{document_id}.metadata", json.dumps({"visibleName": document_id, "parent": "", "type": "DocumentType"}))
        archive.writestr(f"{document_id}.pdf", pdf.tobytes())
        archive.writestr(f"{document_id}.pagedata", "Blank\n" * len(ids))
        for page_id, data in (strokes or {}).items():
            archive.writestr(f"{document_id}/{page_id}.rm", data)
    return path


class NativeMigrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.cwd() / ".tmp")
        self.directory = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def test_remaps_native_bytes_tags_and_preserves_target_page_state(self):
        source = NativeDocument(fixture(self.directory, "source", ["a", "b", "c"], {"b": b"\x00\xffnative bytes"}, modern=True))
        source.content["pageTags"] = [{"name": "work", "pageId": "b", "timestamp": 1}]
        target = NativeDocument(fixture(self.directory, "target", ["x", "y", "z"]))
        target.content["zoomMode"] = "bestFit"
        mapping = [{"source_index": i, "output_index": i} for i in range(3)]
        output = self.directory / "result.rmdoc"
        records = attach(source, target, mapping, output)
        result = NativeDocument(output)
        self.assertEqual(result.files["target/y.rm"], source.files["source/b.rm"])
        self.assertEqual(result.content["pages"], ["x", "y", "z"])
        self.assertEqual(result.content["formatVersion"], 1)
        self.assertEqual(result.content["pageTags"][0]["pageId"], "y")
        self.assertEqual(result.content["zoomMode"], "fitToHeight")
        self.assertEqual(verify_attachment(source, result, mapping)["native_files"], 1)
        self.assertEqual(records[0]["output_index"], 1)

    def test_detects_corrupted_native_bytes(self):
        source = NativeDocument(fixture(self.directory, "source", ["a", "b"], {"b": b"binary ink"}))
        target = NativeDocument(fixture(self.directory, "target", ["x", "y"], {"y": b"corrupted"}))
        with self.assertRaisesRegex(ValueError, "stroke"):
            verify_attachment(source, target, [{"source_index": i, "output_index": i} for i in range(2)])

    def test_rejects_target_ink_and_incomplete_mapping(self):
        source = NativeDocument(fixture(self.directory, "source", ["a", "b"], {"b": b"ink"}))
        target = NativeDocument(fixture(self.directory, "target", ["x", "y"], {"y": b"new ink"}))
        with self.assertRaisesRegex(ValueError, "destination.*ink"):
            attach(source, target, [{"source_index": i, "output_index": i} for i in range(2)], self.directory / "blocked.rmdoc")
        clean = NativeDocument(fixture(self.directory, "clean", ["x", "y"]))
        with self.assertRaisesRegex(ValueError, "mapping"):
            attach(source, clean, [{"source_index": 0, "output_index": 0}], self.directory / "incomplete.rmdoc")

    def test_rejects_unknown_native_pages(self):
        path = fixture(self.directory, "source", ["a"], {"unknown": b"ink"})
        with self.assertRaisesRegex(ValueError, "unmapped"):
            NativeDocument(path)

    def test_rejects_reordered_native_pages_before_building(self):
        path = fixture(self.directory, "source", ["a", "b"])
        with zipfile.ZipFile(path) as archive:
            files = {name: archive.read(name) for name in archive.namelist()}
        content = json.loads(files["source.content"])
        content["redirectionPageMap"] = [1, 0]
        files["source.content"] = json.dumps(content).encode()
        with zipfile.ZipFile(path, "w") as archive:
            for name, data in files.items():
                archive.writestr(name, data)
        with self.assertRaisesRegex(ValueError, "Reordered"):
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
