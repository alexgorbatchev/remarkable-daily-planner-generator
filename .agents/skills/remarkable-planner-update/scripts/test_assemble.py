import tempfile
import unittest
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from pypdf.generic import ArrayObject, DictionaryObject, NameObject, NumberObject

from assemble import assemble


class AssembleTests(unittest.TestCase):
    def setUp(self):
        Path(".tmp").mkdir(exist_ok=True)
        self.scratch = tempfile.TemporaryDirectory(dir=".tmp")
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        self.old = self.root / "old.pdf"
        self.new = self.root / "new.pdf"
        self.output = self.root / "result.pdf"
        for path in (self.old, self.new):
            writer = PdfWriter()
            writer.add_blank_page(100, 200)
            writer.add_blank_page(100, 200)
            annotation = DictionaryObject({
                NameObject("/Type"): NameObject("/Annot"),
                NameObject("/Subtype"): NameObject("/Link"),
                NameObject("/Rect"): ArrayObject([NumberObject(n) for n in (1, 2, 20, 30)]),
            })
            destination = ArrayObject([writer.pages[1].indirect_reference, NameObject("/Fit")])
            if path == self.old:
                annotation[NameObject("/A")] = DictionaryObject({
                    NameObject("/S"): NameObject("/GoTo"), NameObject("/D"): destination,
                })
            else:
                annotation[NameObject("/Dest")] = destination
            writer.add_annotation(0, annotation)
            writer.write(path)
        self.sources = {"old": self.old, "new": self.new}
        self.selections = [("new", 1), ("old", 0), ("old", 1), ("new", 0)]
        self.targets = {("old", 1): 2, ("new", 1): 0}

    def test_reorders_both_link_formats_without_cross_source_collisions(self):
        count = assemble(self.sources, self.selections, self.targets, {}, self.output)
        reader = PdfReader(self.output, strict=True)
        self.assertEqual(count, 2)
        self.assertEqual(len(reader.pages), 4)
        for page, target in ((1, 2), (3, 0)):
            destination = reader.pages[page]["/Annots"][0].get_object()["/Dest"]
            self.assertEqual(reader.get_page_number(destination[0].get_object()), target)

    def test_missing_destination_does_not_create_output(self):
        with self.assertRaisesRegex(ValueError, "Unmapped destination"):
            assemble(self.sources, self.selections, {}, {}, self.output)
        self.assertFalse(self.output.exists())

    def test_existing_output_is_preserved(self):
        self.output.write_bytes(b"keep this file")
        with self.assertRaises(FileExistsError):
            assemble(self.sources, self.selections, self.targets, {}, self.output)
        self.assertEqual(self.output.read_bytes(), b"keep this file")

    def test_overlay_dimensions_are_checked(self):
        overlay = self.root / "overlay.pdf"
        writer = PdfWriter()
        writer.add_blank_page(200, 200)
        writer.write(overlay)
        with self.assertRaisesRegex(ValueError, "Overlay dimensions"):
            assemble(self.sources, self.selections, self.targets, {0: overlay}, self.output)
        self.assertFalse(self.output.exists())
