"""Assemble planner pages and vector overlays with explicit cross-PDF link mapping.

Import assemble() from a task-specific Python driver; this module has no CLI or
network access. Inputs and existing output files are never overwritten.
"""

from pathlib import Path

from pypdf import PdfReader, PdfWriter
from pypdf.generic import ArrayObject, DictionaryObject, NameObject


def assemble(
    sources: dict[str, Path],
    selections: list[tuple[str, int]],
    destinations: dict[tuple[str, int], int],
    overlays: dict[int, Path],
    output: Path,
) -> int:
    """Return link count after writing a new PDF; all page indices are zero-based.

    selections contains (source name, source page) in final output order.
    destinations maps any referenced source page to its final replacement index,
    including source pages whose artwork is not selected.
    overlays maps final page indices to single-page, transparent PDF artwork.
    Only explicit internal PDF links are supported; reject other annotations,
    actions and named destinations instead of silently removing their behavior.
    Source outlines, tagging and document-level metadata are not imported.
    """
    if output.exists():
        raise FileExistsError(output)
    if not selections:
        raise ValueError("Select at least one page")
    if any(index < 0 or index >= len(selections) for index in overlays):
        raise ValueError("Overlay page index outside output")
    if any(index < 0 or index >= len(selections) for index in destinations.values()):
        raise ValueError("Destination page index outside output")
    readers = {name: PdfReader(path) for name, path in sources.items()}
    references = {
        name: {page.indirect_reference.idnum: index for index, page in enumerate(reader.pages)}
        for name, reader in readers.items()
    }
    writer = PdfWriter()
    for final_index, (name, source_index) in enumerate(selections):
        if source_index < 0 or source_index >= len(readers[name].pages):
            raise ValueError(f"Source page index outside document: {name}, {source_index}")
        source = readers[name].pages[source_index]
        # Prevent cloning an old link's entire page graph. Rebuild links below.
        annotations = source.pop("/Annots", None)
        try:
            page = writer.add_page(source, excluded_keys=["/StructParents"])
        finally:
            if annotations is not None:
                source[NameObject("/Annots")] = annotations
        if final_index in overlays:
            overlay = PdfReader(overlays[final_index])
            if len(overlay.pages) != 1:
                raise ValueError("Each overlay must contain exactly one page")
            ink = overlay.pages[0]
            if page.rotation or ink.rotation:
                raise ValueError("Normalize rotation before applying overlays")
            if any(abs(float(a) - float(b)) > 0.001 for a, b in zip(page.mediabox, ink.mediabox)):
                raise ValueError(f"Overlay dimensions differ at page {final_index}")
            if ink.get("/Annots"):
                raise ValueError("Overlay annotations are unsupported")
            page.merge_page(ink)

    link_count = 0
    for final_index, (name, source_index) in enumerate(selections):
        for reference in readers[name].pages[source_index].get("/Annots", []):
            original = reference.get_object()
            if original.get("/Subtype") != "/Link":
                raise ValueError("Only planner link annotations are supported")
            destination = original.get("/Dest")
            if destination is None:
                action = original.get("/A")
                if action is None or action.get_object().get("/S") != "/GoTo":
                    raise ValueError("Only internal GoTo links are supported")
                destination = action.get_object()["/D"]
            destination = destination.get_object()
            if not isinstance(destination, ArrayObject) or not destination:
                raise ValueError("Resolve named destinations before assembling")
            target_index = references[name][destination[0].idnum]
            key = (name, target_index)
            if key not in destinations:
                raise ValueError(f"Unmapped destination: {key}")
            annotation = DictionaryObject()
            for field, value in original.items():
                if field not in {"/Dest", "/A", "/P", "/StructParent", "/Contents"}:
                    annotation[field] = value.clone(writer)
            annotation[NameObject("/Dest")] = ArrayObject([
                writer.pages[destinations[key]].indirect_reference,
                *(value.clone(writer) for value in destination[1:]),
            ])
            writer.add_annotation(final_index, annotation)
            link_count += 1

    for page in writer.pages:
        page.compress_content_streams()
    writer.compress_identical_objects()
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("xb") as stream:
        writer.write(stream)
    return link_count
