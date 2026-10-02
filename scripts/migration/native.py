"""Preserve native page identity and copy handwriting without decoding it."""

import hashlib
import json
import zipfile
from pathlib import Path

VIEWPORT_FIELDS = ("zoomMode", "viewBackgroundFilter", "customZoomCenterX", "customZoomCenterY", "customZoomOrientation", "customZoomPageHeight", "customZoomPageWidth", "customZoomScale")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def write_json(path, value):
    temporary = path.with_suffix(path.suffix + ".new")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


class NativeDocument:
    def __init__(self, path):
        self.path = Path(path)
        with zipfile.ZipFile(self.path) as archive:
            names = archive.namelist()
            if len(names) != len(set(names)) or archive.testzip() is not None:
                raise ValueError("Invalid or duplicate archive entries")
            if any(Path(n).is_absolute() or ".." in Path(n).parts for n in names):
                raise ValueError("Unsafe archive path")
            entries = {n: archive.read(n) for n in names if not n.endswith("/")}
        if not {"evidence/snapshot.json", "evidence/document.docSchema"} <= entries.keys():
            raise ValueError("Expected a complete remarkable doc archive ZIP with snapshot evidence")
        self.snapshot = json.loads(entries["evidence/snapshot.json"])
        if self.snapshot["format_version"] != 1 or digest(entries["evidence/document.docSchema"]) != self.snapshot["manifest_sha256"]:
            raise ValueError("Invalid remarkable archive evidence")
        self.files = {name.removeprefix("files/"): data for name, data in entries.items() if name.startswith("files/")}
        records = self.snapshot["files"]
        if len(records) != len(self.files) or {r["name"] for r in records} != set(self.files) or set(entries) != {"files/" + n for n in self.files} | {"evidence/snapshot.json", "evidence/document.docSchema"}:
            raise ValueError("Archive files differ from snapshot evidence")
        for record in records:
            data = self.files[record["name"]]
            if len(data) != record["size"] or digest(data) != record["sha256"] or digest(data) != record["hash"]:
                raise ValueError(f"Native archive hash differs: {record['name']}")
        contents = [n for n in self.files if n.endswith(".content") and "/" not in n]
        if len(contents) != 1:
            raise ValueError("Expected one native document in the archive")
        self.id = contents[0].removesuffix(".content")
        if self.id != self.snapshot["document_id"]:
            raise ValueError("Native archive identity differs from evidence")
        self.content = json.loads(self.files[contents[0]])
        self.metadata = json.loads(self.files[f"{self.id}.metadata"])
        self.pdf = self.files[f"{self.id}.pdf"]
        if self.content.get("fileType") != "pdf":
            raise ValueError("Only native PDF planners are supported")
        self.pages = self._pages()
        self.strokes = {}
        by_id = {page_id: index for index, page_id in self.pages.items()}
        for name, data in self.files.items():
            if name.endswith(".rm"):
                page_id = Path(name).stem
                if name != f"{self.id}/{page_id}.rm" or page_id not in by_id:
                    raise ValueError(f"unmapped native stroke file: {name}")
                self.strokes[by_id[page_id]] = data
            elif name not in {f"{self.id}.{ext}" for ext in ("content", "metadata", "pdf", "pagedata")}:
                raise ValueError(f"Unsupported native attachment; preserve it before proceeding: {name}")

    def _pages(self):
        version = self.content.get("formatVersion", 1)
        if version == 2:
            entries = self.content["cPages"]["pages"]
            if any(p.get("deleted", {}).get("value", 0) for p in entries):
                raise ValueError("Deleted native pages require an explicit inventory")
            pairs = [(p["redir"]["value"], p["id"]) for p in entries]
        elif version == 1:
            ids = self.content.get("pages", [])
            redirects = self.content.get("redirectionPageMap", [])
            if ids is None and not redirects:
                return {}
            if not isinstance(ids, list) or not isinstance(redirects, list):
                raise ValueError("Native PDF page IDs have not been initialized")
            if len(ids) != len(redirects):
                raise ValueError("Native page IDs and PDF redirections differ")
            pairs = list(zip(redirects, ids))
        else:
            raise ValueError(f"Unsupported native format version: {version}")
        if len({i for i, _ in pairs}) != len(pairs) or len({p for _, p in pairs}) != len(pairs):
            raise ValueError("Duplicate native page identity or redirection")
        if pairs and (set(i for i, _ in pairs) != set(range(len(pairs))) or len(pairs) != self.content["pageCount"]):
            raise ValueError("Inserted/reordered PDF redirections require an explicit inventory")
        if [index for index, _ in pairs] != list(range(len(pairs))):
            raise ValueError("Reordered native pages are not supported by this migration flow")
        return dict(pairs)

    def hashes(self):
        return {name: digest(data) for name, data in self.files.items()}


def page_mapping(source, target, plan):
    result = {}
    outputs = set()
    for page in plan:
        index = page.get("source_index")
        if index is None:
            continue
        output = page["output_index"]
        if index in result or output in outputs or output not in target.pages:
            raise ValueError("Invalid or duplicate stroke mapping")
        result[index] = output
        outputs.add(output)
    if set(result) != set(source.pages):
        raise ValueError("Incomplete source-to-destination mapping")
    return result


def prepare_transfer(source, target, plan, directory):
    if source.id == target.id:
        raise ValueError("The destination must be a separate document")
    if target.strokes:
        raise ValueError("The destination contains new ink; do not overwrite it")
    mapping = page_mapping(source, target, plan)
    records = []
    imports = []
    for index, data in source.strokes.items():
        output_index = mapping[index]
        name = f"page-{index:04d}.rm"
        with (directory / name).open("xb") as file:
            file.write(data)
        imports.append({"source": name, "page": output_index})
        records.append({"source_index": index, "output_index": output_index, "source_page_id": source.pages[index], "destination_page_id": target.pages[output_index], "bytes": len(data), "sha256": digest(data)})
    write_json(directory / "import-map.json", imports)
    write_json(directory / "settings-map.json", [{"source_page": i, "destination_page": o} for i, o in mapping.items()])
    write_json(directory / "stroke-map.json", records)
    return records


def verify_strokes(source, target, plan):
    mapping = page_mapping(source, target, plan)
    expected = {mapping[index]: data for index, data in source.strokes.items()}
    if expected != target.strokes:
        raise ValueError("Native stroke bytes or page associations differ")
    return mapping


def verify_preservation(source, target, plan, baseline):
    mapping = page_mapping(source, target, plan)
    if target.pages != baseline.pages:
        raise ValueError("Destination native page identity or order changed")
    copied_names = {f"{target.id}/{target.pages[mapping[i]]}.rm" for i in source.strokes}
    if set(target.files) != set(baseline.files) | copied_names:
        raise ValueError("Destination native attachment set changed unexpectedly")
    for name, data in baseline.files.items():
        if not name.endswith((".metadata", ".content")) and name not in copied_names and target.files[name] != data:
            raise ValueError(f"Destination attachment changed: {name}")
    ignored = set(VIEWPORT_FIELDS) | {"tags", "pageTags"}
    if {k: v for k, v in target.content.items() if k not in ignored} != {k: v for k, v in baseline.content.items() if k not in ignored}:
        raise ValueError("Unrelated destination native content changed")
    if {k: v for k, v in target.metadata.items() if k != "lastModified"} != {k: v for k, v in baseline.metadata.items() if k != "lastModified"}:
        raise ValueError("Unrelated destination metadata changed")


def verify_attachment(source, target, plan, baseline=None):
    mapping = verify_strokes(source, target, plan)
    id_mapping = {source.pages[i]: target.pages[o] for i, o in mapping.items()}
    tags = [{**tag, "pageId": id_mapping[tag["pageId"]]} for tag in source.content.get("pageTags", [])]
    if baseline is not None:
        mapped_ids = set(id_mapping.values())
        tags += [tag for tag in baseline.content.get("pageTags", []) if tag["pageId"] not in mapped_ids]
    def by_page(rows):
        groups = {}
        for tag in rows:
            groups.setdefault(tag["pageId"], []).append(tag)
        return groups
    if by_page(tags) != by_page(target.content.get("pageTags", [])) or source.content.get("tags", []) != target.content.get("tags", []):
        raise ValueError("Native tags differ")
    for key in VIEWPORT_FIELDS:
        if (key in source.content) != (key in target.content) or target.content.get(key) != source.content.get(key):
            raise ValueError(f"Native viewport differs: {key}")
    if baseline is not None:
        verify_preservation(source, target, plan, baseline)
    return {"status": "PASS", "native_files": len(source.strokes), "native_bytes": sum(map(len, source.strokes.values())), "destination_id": target.id, "pdf_sha256": digest(target.pdf)}
