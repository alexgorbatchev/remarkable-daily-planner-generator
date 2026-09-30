"""Preserve native page identity and copy handwriting without decoding it."""

import copy
import hashlib
import json
import zipfile
from pathlib import Path


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
            self.files = {n: archive.read(n) for n in names if not n.endswith("/")}
        contents = [n for n in self.files if n.endswith(".content") and "/" not in n]
        if len(contents) != 1:
            raise ValueError("Expected one native document in the archive")
        self.id = contents[0].removesuffix(".content")
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
            if ids is None and redirects is None and self.content.get("pageCount") == 0:
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


def attach(source, target, plan, output):
    if source.id == target.id:
        raise ValueError("The destination must be a separate document")
    if target.strokes:
        raise ValueError("The destination contains new ink; do not overwrite it")
    mapping = page_mapping(source, target, plan)
    files = dict(target.files)
    content = copy.deepcopy(target.content)
    for key, value in source.content.items():
        if key == "zoomMode" or key == "viewBackgroundFilter" or key.startswith("customZoom"):
            content[key] = value
    id_mapping = {source.pages[i]: target.pages[o] for i, o in mapping.items()}
    content.setdefault("pageTags", [])
    content.setdefault("tags", [])
    for tag in source.content.get("pageTags", []):
        remapped = {**tag, "pageId": id_mapping[tag["pageId"]]}
        if remapped not in content["pageTags"]:
            content["pageTags"].append(remapped)
    for tag in source.content.get("tags", []):
        if tag not in content["tags"]:
            content["tags"].append(copy.deepcopy(tag))
    files[f"{target.id}.content"] = json.dumps(content, indent=2).encode()
    records = []
    for index, data in source.strokes.items():
        output_index = mapping[index]
        destination = f"{target.id}/{target.pages[output_index]}.rm"
        files[destination] = data
        records.append({"source_index": index, "output_index": output_index, "source_page_id": source.pages[index], "destination_page_id": target.pages[output_index], "bytes": len(data), "sha256": digest(data)})
    with zipfile.ZipFile(output, "x", compression=zipfile.ZIP_DEFLATED) as archive:
        for name, data in files.items():
            archive.writestr(name, data)
    verify_attachment(source, NativeDocument(output), plan)
    return records


def verify_attachment(source, target, plan):
    mapping = page_mapping(source, target, plan)
    expected = {mapping[index]: data for index, data in source.strokes.items()}
    if expected != target.strokes:
        raise ValueError("Native stroke bytes or page associations differ")
    id_mapping = {source.pages[i]: target.pages[o] for i, o in mapping.items()}
    tags = [{**tag, "pageId": id_mapping[tag["pageId"]]} for tag in source.content.get("pageTags", [])]
    if any(tag not in target.content.get("pageTags", []) for tag in tags) or any(tag not in target.content.get("tags", []) for tag in source.content.get("tags", [])):
        raise ValueError("Native tags differ")
    for key, value in source.content.items():
        if (key in ("zoomMode", "viewBackgroundFilter") or key.startswith("customZoom")) and target.content.get(key) != value:
            raise ValueError(f"Native viewport differs: {key}")
    return {"status": "PASS", "native_files": len(expected), "native_bytes": sum(map(len, expected.values())), "destination_id": target.id, "pdf_sha256": digest(target.pdf)}
