"""Persist migration stages; no cloud writes occur during preparation."""

import fcntl
import json
import shutil
from contextlib import contextmanager
from pathlib import Path
from uuid import UUID, uuid4

from .background import build_background, inventory, plan_pages
from .cloud import Cloud
from .native import NativeDocument, attach, digest, verify_attachment, write_json


def load(work):
    state = json.loads((work / "migration.json").read_text())
    if state["version"] != 1:
        raise ValueError("Unsupported migration manifest version")
    return state


def save(work, state):
    write_json(work / "migration.json", state)


@contextmanager
def locked(work):
    with (work / ".lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError("Another process is operating on this migration") from None
        try:
            yield
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def validate_title(title):
    if not title.strip() or title in (".", "..") or any(c in title for c in "/\\\n\r\0"):
        raise ValueError("Use a nonempty document title without path separators")


def prepare(root, work, source, source_archive, cutoff, title, country, standup, binary, source_map=None):
    validate_title(title)
    if "/" in binary:
        binary = str(Path(binary).resolve())
    work = work.resolve()
    if not work.is_relative_to(root / ".tmp"):
        raise ValueError("Migration work directories must be inside the repository's .tmp")
    work.mkdir(parents=True, exist_ok=False)
    with locked(work):
        if source_archive:
            backup = work / "source.rmdoc"
            shutil.copyfile(source_archive, backup)
            document = NativeDocument(backup)
        else:
            try:
                UUID(source)
                by_id = True
            except ValueError:
                by_id = False
            document = Cloud(binary, work).download(source, by_id=by_id)
        if document.metadata["visibleName"] == title:
            raise ValueError("Choose a new title; the original document must remain intact")
        supplied = json.loads(source_map.read_text()) if source_map else None
        pages = inventory(document, cutoff.year, supplied)
        plan = plan_pages(pages, cutoff.isoformat(), standup)
        state = {"version": 1, "stage": "preparing", "source_id": document.id, "source_archive": str(document.path.relative_to(work)), "source_hashes": document.hashes(), "title": title, "cutoff": cutoff.isoformat(), "country": country, "rmapi": binary, "plan": plan}
        save(work, state)
        state["background"] = build_background(root, work, document, pages, plan, cutoff.year, country)
        state["stage"] = "prepared"
        save(work, state)
        write_json(work / "preparation-verification.json", {"status": "PASS", **state["background"], "source_id": document.id, "source_native_files": len(document.strokes), "new_pages": len(plan) - len(pages)})
        return state


def checked_background(work, state):
    path = work / "background.pdf"
    if digest(path.read_bytes()) != state["background"]["pdf_sha256"]:
        raise ValueError("Prepared PDF changed since verification")
    return path


def fresh_source(work, state, cloud):
    source = cloud.download(state["source_id"])
    if source.hashes() != state["source_hashes"]:
        raise ValueError("Source changed since preparation; prepare a fresh run so no recent edits are lost")
    return source


def check_destination(target, state):
    if target.id == state["source_id"] or target.metadata["visibleName"] != state["title"]:
        raise ValueError("Destination identity differs from the separate migration document")
    if digest(target.pdf) != state["background"]["pdf_sha256"]:
        raise ValueError("Destination PDF differs from the prepared background")


def publish(work):
    with locked(work):
        state = load(work)
        if state["stage"] not in ("prepared", "publishing", "awaiting_page_ids"):
            raise ValueError(f"Cannot publish migration at stage {state['stage']}")
        checked_background(work, state)
        cloud = Cloud(state["rmapi"], work)
        fresh_source(work, state, cloud)
        found = cloud.stat(state["title"])
        if found and state["stage"] == "prepared":
            raise ValueError("That destination title already exists; choose an unused title")
        if found and state.get("destination_id") and found["ID"] != state["destination_id"]:
            raise ValueError("Destination ID changed; do not replace another document")
        if not found:
            if state["stage"] == "awaiting_page_ids":
                raise ValueError("Previously uploaded destination is absent; inspect cloud state before retrying")
            upload_dir = work / "upload-background"
            upload_dir.mkdir(exist_ok=True)
            path = upload_dir / (state["title"] + ".pdf")
            shutil.copyfile(work / "background.pdf", path)
            state["stage"] = "publishing"
            save(work, state)
            cloud.put(path)
            found = cloud.stat(state["title"])
            if found is None:
                raise ValueError("Upload not visible; resume publish to inspect it before retrying")
        target = cloud.download(found["ID"])
        check_destination(target, state)
        if target.strokes:
            raise ValueError("Destination already contains new ink; do not replace it")
        state.update(stage="awaiting_page_ids", destination_id=target.id)
        save(work, state)
        return state


def verify_remote(work, state, cloud, source, target):
    check_destination(target, state)
    report = verify_attachment(source, target, state["plan"])
    prepared = NativeDocument(work / state["prepared_archive"])
    if target.pages != prepared.pages:
        raise ValueError("Uploaded native page identity or order differs")
    for name, data in prepared.files.items():
        if not name.endswith((".metadata", ".content")) and target.files.get(name) != data:
            raise ValueError(f"Uploaded native document differs: {name}")
    for key in ("tags", "pageTags"):
        if any(tag not in target.content.get(key, []) for tag in prepared.content.get(key, [])):
            raise ValueError("Uploaded document lost destination tags")
    original = cloud.download(state["source_id"])
    if original.hashes() != state["source_hashes"]:
        raise ValueError("Original document changed during the transfer; backups are retained")
    report.update(cloud_verified=True, original_files_unchanged=True, downloaded_archive=str(target.path.relative_to(work)))
    write_json(work / "cloud-verification.json", report)
    state.update(stage="complete", verification=report)
    save(work, state)
    return state


def resume(work):
    with locked(work):
        state = load(work)
        if state["stage"] not in ("awaiting_page_ids", "attaching", "complete"):
            raise ValueError("Publish the prepared background before resuming the native transfer")
        checked_background(work, state)
        cloud = Cloud(state["rmapi"], work)
        source = fresh_source(work, state, cloud)
        found = cloud.stat(state["title"])
        if found is None:
            if state["stage"] != "attaching":
                raise ValueError("Destination is absent; inspect cloud state before continuing")
            prepared_path = work / state["prepared_archive"]
            prepared = NativeDocument(prepared_path)
            check_destination(prepared, state)
            if prepared.id != state["destination_id"]:
                raise ValueError("Prepared archive UUID differs from the saved destination")
            verify_attachment(source, prepared, state["plan"])
            # Recover a force upload interrupted after deletion. The title is
            # absent, so normal put restores the retained staging archive.
            cloud.put(prepared_path)
        elif found["ID"] != state["destination_id"]:
            raise ValueError("Destination title now belongs to a different document")
        target = cloud.download(state["destination_id"])
        check_destination(target, state)
        if state["stage"] in ("attaching", "complete"):
            try:
                verify_attachment(source, target, state["plan"])
            except ValueError:
                if target.strokes or state["stage"] == "complete":
                    raise ValueError("Destination has unexpected ink; inspect the retained backups before another upload") from None
            else:
                return verify_remote(work, state, cloud, source, target)
        if len(target.pages) != state["background"]["page_count"]:
            return {**state, "message": "Open the new document on the tablet, return to My files, sync, then resume this run."}
        if target.strokes:
            raise ValueError("The destination contains new ink; do not overwrite it")
        directory = work / f"native-{uuid4().hex}"
        directory.mkdir()
        prepared_path = directory / (state["title"] + ".rmdoc")
        records = attach(source, target, state["plan"], prepared_path)
        write_json(directory / "stroke-map.json", records)
        state.update(stage="attaching", prepared_archive=str(prepared_path.relative_to(work)))
        save(work, state)
        # rmapi --force recreates only the distinct staging document. Its archive
        # retains the staging UUID and the tablet-generated native page IDs.
        found = cloud.stat(state["title"])
        if not found or found["ID"] != state["destination_id"]:
            raise ValueError("Destination identity changed immediately before upload")
        latest = cloud.download(state["destination_id"])
        if latest.hashes() != target.hashes():
            raise ValueError("Destination changed while assembling; resume with a fresh snapshot")
        fresh_source(work, state, cloud)
        cloud.put(prepared_path, replace=True)
        uploaded = cloud.download(state["destination_id"])
        return verify_remote(work, state, cloud, source, uploaded)
