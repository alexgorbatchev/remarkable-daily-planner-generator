"""Persist migration stages; all cloud access uses the remarkable CLI."""

import fcntl
import json
import shutil
from contextlib import contextmanager
from pathlib import Path
from uuid import UUID, uuid4

from .background import build_background, inventory, plan_pages
from .cloud import Cloud
from .native import NativeDocument, prepare_transfer, digest, verify_attachment, verify_preservation, verify_strokes, write_json


def load(work):
    state = json.loads((work / "migration.json").read_text())
    if state["version"] != 2:
        raise ValueError("Unsupported migration manifest version; prepare a fresh remarkable run")
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
            backup = work / "source.zip"
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
        state = {"version": 2, "stage": "preparing", "source_id": document.id, "source_archive": str(document.path.relative_to(work)), "source_hashes": document.hashes(), "title": title, "cutoff": cutoff.isoformat(), "country": country, "remarkable": binary, "plan": plan}
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


def upload_identity(evidence, state):
    value = json.loads(evidence.read_text())
    if value["version"] != 1 or value["title"] != state["title"] or value["folder"] != "" or value["pages"] != state["background"]["page_count"]:
        raise ValueError("Upload evidence differs from the saved migration")
    identity = value["result"]["id"]
    UUID(identity)
    files = value["files"]
    if len(files) != 4 or {f["name"] for f in files} != {f"{identity}.{ext}" for ext in ("pdf", "metadata", "content", "pagedata")}:
        raise ValueError("Upload evidence attachment identity differs")
    pdf = next(f for f in files if f["name"] == f"{identity}.pdf")
    if pdf["sha256"] != state["background"]["pdf_sha256"]:
        raise ValueError("Upload evidence PDF differs from the reviewed background")
    return identity


def publish(work):
    with locked(work):
        state = load(work)
        if state["stage"] not in ("prepared", "publishing", "awaiting_page_ids"):
            raise ValueError(f"Cannot publish migration at stage {state['stage']}")
        background = checked_background(work, state)
        cloud = Cloud(state["remarkable"], work)
        fresh_source(work, state, cloud)
        if state["stage"] == "awaiting_page_ids":
            target = cloud.download(state["destination_id"])
            check_destination(target, state)
            return state
        evidence = work / "upload.json"
        if state["stage"] == "prepared":
            if cloud.stat(state["title"]) is not None:
                raise ValueError("That destination title already exists; choose an unused title")
            if evidence.exists():
                raise ValueError("Unexpected upload evidence; inspect it before publishing")
            state["stage"] = "publishing"
            save(work, state)
        if not evidence.exists():
            # The CLI writes evidence before staging any cloud data. Absence
            # means creation has not started; every other retry uses saved ID.
            cloud.upload(background, state["title"], evidence)
        identity = upload_identity(evidence, state)
        if state.get("destination_id") and state["destination_id"] != identity:
            raise ValueError("Saved destination ID differs from upload evidence")
        try:
            cloud.upload_check(evidence)
        except RuntimeError:
            # Tablet initialization can invalidate the creation document hash.
            # Inspect the saved UUID and exact background; never create a copy.
            state["upload_recovery"] = "Inspecting saved UUID after upload-check failure"
        target = cloud.download(identity)
        check_destination(target, state)
        if target.strokes:
            raise ValueError("Destination already contains new ink; do not replace it")
        state.update(stage="awaiting_page_ids", destination_id=identity)
        save(work, state)
        return state


def verify_remote(work, state, cloud, source, target):
    check_destination(target, state)
    baseline = NativeDocument(work / state["destination_archive"])
    report = verify_attachment(source, target, state["plan"], baseline)
    original = fresh_source(work, state, cloud)
    report.update(cloud_verified=True, original_files_unchanged=original.hashes() == state["source_hashes"], downloaded_archive=str(target.path.relative_to(work)))
    write_json(work / "cloud-verification.json", report)
    state.update(stage="complete", verification=report)
    save(work, state)
    return state


def resume(work):
    with locked(work):
        state = load(work)
        if state["stage"] not in ("awaiting_page_ids", "importing", "settings", "complete"):
            raise ValueError("Publish the prepared background before resuming the native transfer")
        checked_background(work, state)
        cloud = Cloud(state["remarkable"], work)
        source = fresh_source(work, state, cloud)
        target = cloud.download(state["destination_id"])
        check_destination(target, state)
        if state["stage"] == "complete":
            return verify_remote(work, state, cloud, source, target)
        if len(target.pages) != state["background"]["page_count"]:
            if state["stage"] != "awaiting_page_ids":
                raise ValueError("Destination native page structure changed during attachment")
            return {**state, "message": "Open the new document on the tablet, return to My files, sync, then resume this run."}
        if state["stage"] == "awaiting_page_ids":
            directory = work / f"native-{uuid4().hex}"
            directory.mkdir()
            prepare_transfer(source, target, state["plan"], directory)
            state.update(stage="importing", destination_archive=str(target.path.relative_to(work)), transfer_dir=str(directory.relative_to(work)))
            save(work, state)
        baseline = NativeDocument(work / state["destination_archive"])
        directory = work / state["transfer_dir"]
        if target.pages != baseline.pages:
            raise ValueError("Destination native page identity or order changed")
        if state["stage"] == "importing":
            if target.strokes:
                # A committed import may have returned an error or lost stdout.
                # Only exact complete bytes allow recovery; partial ink stops.
                verify_strokes(source, target, state["plan"])
            elif source.strokes:
                if target.hashes() != baseline.hashes():
                    raise ValueError("Destination changed before native import")
                fresh_source(work, state, cloud)
                cloud.import_strokes(target.id, directory / "import-map.json")
                target = cloud.download(target.id)
                verify_strokes(source, target, state["plan"])
            state["stage"] = "settings"
            save(work, state)
        verify_preservation(source, target, state["plan"], baseline)
        try:
            verify_attachment(source, target, state["plan"], baseline)
        except ValueError:
            # Before settings transfer, only the stroke import's file changes
            # and lastModified update are allowed. A prior settings commit is
            # accepted above only if the complete expected result verifies.
            if target.files[f"{target.id}.content"] != baseline.files[f"{target.id}.content"]:
                raise ValueError("Destination settings changed unexpectedly; inspect retained evidence") from None
            verify_strokes(source, target, state["plan"])
            fresh_source(work, state, cloud)
            cloud.transfer_settings(source.id, target.id, directory / "settings-map.json")
            target = cloud.download(target.id)
        return verify_remote(work, state, cloud, source, target)
