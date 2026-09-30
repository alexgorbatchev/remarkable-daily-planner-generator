"""Use rmapi's supported archive download and upload commands."""

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
        (work / "rmapi-temp").mkdir(exist_ok=True)

    def command(self, args, cwd=None, missing=False):
        result = subprocess.run([self.binary, "-ni", *args], cwd=cwd or self.work, env={**os.environ, "TMPDIR": str(self.work / "rmapi-temp")}, capture_output=True, text=True, timeout=300)
        log = self.work / f"rmapi-{args[0]}-{uuid4().hex}.log"
        log.write_text(result.stdout + result.stderr)
        if result.returncode:
            if missing and "file doesn't exist" in result.stderr:
                return None
            raise RuntimeError(f"rmapi {args[0]} failed; inspect {log}. Resume the same run before retrying any upload.")
        return result.stdout

    def stat(self, name):
        output = self.command(["stat", name], missing=True)
        return json.loads(output) if output is not None else None

    def download(self, source, by_id=True):
        directory = self.work / f"download-{uuid4().hex}"
        directory.mkdir()
        self.command(["get", *(["--id"] if by_id else []), source], cwd=directory)
        archives = list(directory.glob("*.rmdoc"))
        if len(archives) != 1:
            raise ValueError("rmapi did not download exactly one native archive")
        document = NativeDocument(archives[0])
        if by_id and document.id != source:
            raise ValueError("Downloaded document ID differs from the requested ID")
        return document

    def put(self, path, replace=False):
        self.command(["put", *(["--force"] if replace else []), str(path)])
