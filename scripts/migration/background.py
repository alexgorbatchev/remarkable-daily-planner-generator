"""Inventory logical planner pages and assemble backgrounds with mapped links."""

import io
import json
import re
import runpy
import subprocess
from datetime import date, timedelta

import pymupdf
from pypdf import PdfReader

from .native import digest, write_json

MONTHS = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split()
DATE_PATTERN = re.compile(r"(?:(\d{4})\s+)?(" + "|".join(MONTHS) + r")\s+(\d{1,2})\b")


def inventory(document, year, supplied=None):
    reader = PdfReader(io.BytesIO(document.pdf))
    if len(reader.pages) != len(document.pages):
        raise ValueError("Open the source on the tablet and sync its native page IDs first")
    if supplied:
        if supplied["pdf_sha256"] != digest(document.pdf):
            raise ValueError("The source page map does not match the downloaded PDF")
        pages = supplied["pages"]
    else:
        pages = []
        with pymupdf.open(stream=document.pdf, filetype="pdf") as pdf:
            for index, page in enumerate(pdf):
                text = page.get_text()
                spans = [s for b in page.get_text("dict")["blocks"] if "lines" in b for line in b["lines"] for s in line["spans"] if s["bbox"][1] < 60 and s["size"] >= 10]
                matches = [match for span in spans for match in DATE_PATTERN.finditer(span["text"])]
                if index == 0 and not matches and str(year) in text and "January" in text:
                    kind, day = "calendar", None
                else:
                    dates = {date(int(m[1] or year), MONTHS.index(m[2]) + 1, int(m[3])).isoformat() for m in matches}
                    if len(dates) != 1:
                        raise ValueError(f"Ambiguous date on page {index + 1}; supply --source-map")
                    day = dates.pop()
                    if "Top Priority" in text:
                        kind = "day"
                    elif any(s["color"] == 0xFFFFFF and s["text"] == "Standup" for s in spans):
                        kind = "standup"
                    elif any(s["text"] == "Day" or (s["color"] == 0xFFFFFF and s["text"] == "Notes") for s in spans):
                        kind = "notes"
                    else:
                        raise ValueError(f"Ambiguous page type on page {index + 1}; supply --source-map")
                pages.append({"kind": kind, "date": day})
    if len(pages) != len(document.pages):
        raise ValueError("Source inventory length differs from the PDF")
    seen = set()
    result = []
    for index, record in enumerate(pages):
        kind, day = record["kind"], record["date"]
        if kind not in ("calendar", "day", "notes", "standup") or (kind == "calendar") != (day is None):
            raise ValueError("Unsupported logical page identity")
        if day and date.fromisoformat(day).year != year:
            raise ValueError("Source document year differs from the cutoff year")
        key = kind, day
        if key in seen:
            raise ValueError(f"Duplicate logical page: {key}")
        seen.add(key)
        result.append({"kind": kind, "date": day, "source_index": index, "output_index": index, "native_id": document.pages[index], "has_strokes": index in document.strokes})
    if sum(p["kind"] == "calendar" for p in result) != 1:
        raise ValueError("Expected one annual calendar")
    days = {p["date"] for p in result if p["kind"] == "day"}
    if days != {p["date"] for p in result if p["kind"] == "notes"}:
        raise ValueError("Day and Notes dates differ")
    return result


def plan_pages(pages, cutoff, standup):
    result = [{**p, "source_index": index, "output_index": index, "background": "new" if p["date"] and p["date"] >= cutoff else "old"} for index, p in enumerate(pages)]
    existing = {(p["kind"], p["date"]) for p in pages}
    if standup:
        for day in sorted(p["date"] for p in pages if p["kind"] == "day" and p["date"] >= cutoff):
            if ("standup", day) not in existing:
                result.append({"kind": "standup", "date": day, "source_index": None, "output_index": len(result), "background": "new", "has_strokes": False})
    return result


def annual_dates(year, weekends):
    day = date(year, 1, 1)
    result = []
    while day.year == year:
        if weekends or day.weekday() < 5:
            result.append(day.isoformat())
        day += timedelta(days=1)
    return result


def grid_geometry(page):
    patterns = page.get("/Resources", {}).get("/Pattern", {})
    if hasattr(patterns, "get_object"):
        patterns = patterns.get_object()
    if len(patterns) != 1:
        raise ValueError("Annotated Notes requires one recognized grid pattern")
    pattern = next(iter(patterns.values())).get_object()
    return {key: [float(v) for v in pattern[key]] if key in ("/BBox", "/Matrix") else float(pattern[key]) for key in ("/BBox", "/Matrix", "/XStep", "/YStep")}


def validate_links(sources, selections, destinations, output):
    readers = {name: PdfReader(path) for name, path in sources.items()}
    indexes = {name: {p.indirect_reference.idnum: i for i, p in enumerate(r.pages)} for name, r in readers.items()}
    final = PdfReader(output)
    target_indexes = {p.indirect_reference.idnum: i for i, p in enumerate(final.pages)}
    count = 0
    for index, (name, source_index) in enumerate(selections):
        old = readers[name].pages[source_index].get("/Annots", [])
        new = final.pages[index].get("/Annots", [])
        if len(old) != len(new):
            raise ValueError(f"Link count changed on page {index + 1}")
        for left, right in zip(old, new):
            left, right = left.get_object(), right.get_object()
            destination = left.get("/Dest")
            if destination is None:
                destination = left["/A"].get_object()["/D"]
            expected = destinations[name, indexes[name][destination.get_object()[0].idnum]]
            actual = target_indexes[right["/Dest"][0].idnum]
            if actual != expected or left["/Rect"] != right["/Rect"]:
                raise ValueError(f"Navigation mismatch on page {index + 1}")
            count += 1
    return count


def build_background(root, work, source, pages, plan, year, country):
    dates = sorted(p["date"] for p in pages if p["kind"] == "day")
    weekends = any(date.fromisoformat(day).weekday() >= 5 for day in dates)
    if dates != annual_dates(year, weekends):
        raise ValueError("The source does not contain a complete annual Day/Notes calendar")
    source_path = work / "source.pdf"
    source_path.write_bytes(source.pdf)
    template_keys = [("calendar", None)] + [(kind, day) for kind in ("day", "notes", "standup") for day in dates]
    template_index = {key: index for index, key in enumerate(template_keys)}
    available_standups = {p["date"] for p in plan if p["kind"] == "standup"}
    future_dates = {p["date"] for p in plan if p["kind"] == "day" and p["background"] == "new"}
    if available_standups and not future_dates.issubset(available_standups):
        raise ValueError("Enable --standup to add missing future navigation destinations")
    overrides = []
    for record in plan:
        if record["background"] == "new" and record.get("has_strokes") and record["kind"] == "notes":
            geometry = grid_geometry(PdfReader(source_path).pages[record["source_index"]])
            overrides.append({"date": record["date"], "origin_y": geometry["/Matrix"][5]})
    settings = {"standups": sorted(available_standups), "grid_overrides": overrides}
    settings_path = work / "template-settings.json"
    write_json(settings_path, settings)
    template = work / "template.pdf"
    command = ["typst", "compile", "--root", str(root), "--input", f"year={year}", "--input", f"country={country}", "--input", f"weekends={str(weekends).lower()}", "--input", f"standup={str(bool(available_standups)).lower()}", "--input", f"migration-settings=/{settings_path.relative_to(root).as_posix()}", str(root / "scripts/migration/template.typ"), str(template)]
    subprocess.run(command, cwd=root, check=True, capture_output=True, text=True)
    output_by_key = {(p["kind"], p["date"]): p["output_index"] for p in plan}
    destinations = {("old", p["source_index"]): p["output_index"] for p in plan if p["source_index"] is not None}
    destinations.update({("new", i): output_by_key[key] for key, i in template_index.items() if key in output_by_key})
    selections = [(p["background"], p["source_index"] if p["background"] == "old" else template_index[p["kind"], p["date"]]) for p in plan]
    sources = {"old": source_path, "new": template}
    output = work / "background.pdf"
    assemble = runpy.run_path(root / ".agents/skills/remarkable-planner-update/scripts/assemble.py")["assemble"]
    assemble(sources, selections, destinations, {}, output)
    links = validate_links(sources, selections, destinations, output)
    original, final = PdfReader(source_path), PdfReader(output)
    for record in plan:
        index = record["source_index"]
        page = final.pages[record["output_index"]]
        if index is not None:
            old = original.pages[index]
            if page.mediabox != old.mediabox or page.rotation != old.rotation:
                raise ValueError("Page dimensions or rotation changed")
            if record.get("has_strokes") and record["background"] == "new":
                if record["kind"] == "notes":
                    before, after = grid_geometry(old), grid_geometry(page)
                    for field in ("/BBox", "/XStep", "/YStep"):
                        if before[field] != after[field]:
                            raise ValueError("Annotated Notes grid spacing changed")
                    if any(abs(a - b) > 0.001 for a, b in zip(before["/Matrix"][4:], after["/Matrix"][4:])):
                        raise ValueError("Annotated Notes grid origin changed")
                elif old.get_contents().get_data() != page.get_contents().get_data():
                    raise ValueError("Annotated Day/Standup replacement needs a reviewed geometry override; choose a cutoff after that page")
    write_json(work / "page-map.json", {"pdf_sha256": digest(output.read_bytes()), "pages": [{"kind": p["kind"], "date": p["date"]} for p in plan]})
    return {"page_count": len(plan), "link_count": links, "pdf_sha256": digest(output.read_bytes()), "weekends": weekends}
