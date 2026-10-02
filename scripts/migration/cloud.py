"""Use remarkable's documented native archive, upload, import, and settings APIs."""

import csv
import io
import json
import os
import subprocess
from pathlib import Path
from uuid import uuid4

from .native import NativeDocument


class Cloud:
    def __init__(self, binary, work):
        self.binary = str(Path(binary).resolve()) if "/" in binary else binary
        self.work = work
        (work / "remarkable-temp").mkdir(exist_ok=True)

    def command(self, args):
        command = [self.binary, *args, "--no-cache"]
        log = self.work / f"remarkable-{args[1]}-{uuid4().hex}.json"
        try:
            result = subprocess.run(command, cwd=self.work, env={**os.environ, "AGENT": "1", "TMPDIR": str(self.work / "remarkable-temp")}, capture_output=True, text=True, timeout=330)
        except subprocess.TimeoutExpired as error:
            details = {"command": command, "timeout": True}
            for key in ("stdout", "stderr"):
                value = getattr(error, key)
                details[key] = value.decode("utf-8", errors="replace") if value is not None else ""
            log.write_text(json.dumps(details, indent=2) + "\n")
            raise RuntimeError(f"remarkable timed out; inspect {log} and saved evidence before retrying") from error
        log.write_text(json.dumps({"command": command, "exit_status": result.returncode, "stdout": result.stdout, "stderr": result.stderr}, indent=2) + "\n")
        if result.returncode:
            raise RuntimeError(f"remarkable {args[1]} failed; inspect {log} and saved evidence before retrying")
        return result.stdout

    def verified(self, args):
        output = self.command(args)
        values = {}
        for line in output.splitlines():
            if ": " in line and "\t" not in line:
                key, value = line.split(": ", 1)
                values[key] = value
        if values.get("state") != "verified":
            raise ValueError("remarkable did not report verified; inspect its saved command log")
        return values

    def stat(self, name):
        output = self.command(["doc", "list", "--query", name, "--type", "DocumentType"])
        rows = list(csv.DictReader(io.StringIO(output), delimiter="\t"))
        matches = [r for r in rows if r["NAME"] == name]
        if len(matches) > 1:
            raise ValueError("Destination title is ambiguous; use an unused title")
        return matches[0] if matches else None

    def download(self, source, by_id=True):
        path = self.work / f"archive-{uuid4().hex}.zip"
        self.verified(["doc", "archive", source, "--output", str(path)])
        document = NativeDocument(path)
        if by_id and document.id != source:
            raise ValueError("Downloaded document ID differs from the requested ID")
        return document

    def upload(self, path, title, evidence):
        return self.verified(["doc", "upload", str(path), "--title", title, "--evidence", str(evidence)])

    def upload_check(self, evidence):
        return self.verified(["doc", "upload-check", str(evidence)])

    def import_strokes(self, destination, mapping):
        return self.verified(["doc", "import", destination, "--mapping", str(mapping)])

    def transfer_settings(self, source, destination, mapping):
        return self.verified(["doc", "settings", "transfer", source, destination, "--mapping", str(mapping), "--replace-viewport"])
