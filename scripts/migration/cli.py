"""Click entry points for the resumable native migration workflow."""

import json
import os
import shutil
import subprocess
from functools import wraps
from pathlib import Path
from uuid import uuid4

import click

from . import workflow

ROOT = Path(__file__).resolve().parents[2]


def agent_mode():
    return os.environ.get("AGENT", "").lower() in ("1", "true", "yes")


class TreeGroup(click.Group):
    def format_commands(self, ctx, formatter):
        commands = [(name, self.get_command(ctx, name)) for name in self.list_commands(ctx)]
        if not commands:
            return
        width = shutil.get_terminal_size((80, 24)).columns
        with formatter.section("Commands"):
            def render(items, depth=0):
                name_width = max(len(name) for name, _ in items)
                for index, (name, command) in enumerate(items):
                    prefix = "  " * depth + ("* " if agent_mode() else "╰─ " if index == len(items) - 1 else "├─ ")
                    label = name if agent_mode() else name.ljust(name_width)
                    line = f"{prefix}{label}  {command.get_short_help_str(limit=200)}"
                    formatter.write_text(line if agent_mode() else line[:max(1, width - 4)])
                    if isinstance(command, click.Group):
                        render([(n, command.get_command(ctx, n)) for n in command.list_commands(ctx)], depth + 1)
            render(commands)


def guarded(function):
    @wraps(function)
    def wrapped(*args, **kwargs):
        try:
            return function(*args, **kwargs)
        except (ValueError, RuntimeError, OSError, KeyError, subprocess.SubprocessError) as error:
            if agent_mode():
                raise
            detail = error.stderr if isinstance(error, subprocess.CalledProcessError) else str(error)
            raise click.ClickException(detail) from error
    return wrapped


def display(work, state):
    value = {"work_dir": str(work), "stage": state["stage"], "title": state["title"], "cutoff": state["cutoff"], "page_count": state.get("background", {}).get("page_count"), "message": state.get("message")}
    if agent_mode():
        click.echo(json.dumps(value, separators=(",", ":")))
    else:
        click.echo(f"[OK] {state['stage']}: {state['title']}")
        click.echo(f"Saved run: {work}")
        if state["stage"] == "prepared":
            click.echo(f"Review {work / 'background.pdf'}, then run: just migrate publish '{work}'")
        elif state["stage"] == "awaiting_page_ids":
            click.echo(f"Open the new document on the tablet, return to My files, and let it sync. Then run: just migrate resume '{work}'")
        elif state["stage"] == "complete":
            click.echo("Verified native stroke bytes, PDF, page mapping, and original preservation in the cloud. Let the tablet sync.")
        if state.get("message"):
            click.echo(state["message"])


@click.group(cls=TreeGroup)
def cli():
    """Prepare and transfer reMarkable planners with editable handwriting."""


@cli.group(cls=TreeGroup)
def migration():
    """Create and resume a separate native planner migration."""


@migration.command()
@click.option("--source", help="Source document UUID, exact title, or path in remarkable.")
@click.option("--source-archive", type=click.Path(exists=True, dir_okay=False, path_type=Path), help="Prepare locally from a verified remarkable archive ZIP.")
@click.option("--from", "cutoff", type=click.DateTime(formats=["%Y-%m-%d"]), required=True, help="First date to update, inclusive (YYYY-MM-DD).")
@click.option("--title", required=True, help="Unused title for the separate updated document.")
@click.option("--country", type=click.Choice(["usa", "ca-on", "none"]), default="usa", show_default=True)
@click.option("--standup/--no-standup", default=True, show_default=True, help="Add missing future Standup pages; existing pages survive either setting.")
@click.option("--remarkable", "binary", default=lambda: os.environ.get("REMARKABLE_BIN", "remarkable"), help="remarkable 1.2+ executable; also accepts REMARKABLE_BIN.")
@click.option("--work-dir", type=click.Path(path_type=Path), help="New run directory inside this repository's .tmp.")
@click.option("--source-map", type=click.Path(exists=True, dir_okay=False, path_type=Path), help="Hash-verified page-map.json for custom headers.")
@guarded
def prepare(source, source_archive, cutoff, title, country, standup, binary, work_dir, source_map):
    """Download a backup and build reviewable future backgrounds."""
    if bool(source) == bool(source_archive):
        raise ValueError("Supply exactly one of --source or --source-archive")
    work = (work_dir or ROOT / ".tmp" / f"migration-{cutoff:%Y%m%d}-{uuid4().hex[:8]}").resolve()
    state = workflow.prepare(ROOT, work, source, source_archive, cutoff.date(), title, country, standup, binary, source_map)
    display(work, state)


@migration.command()
@click.argument("work", type=click.Path(exists=True, file_okay=False, path_type=Path))
@guarded
def publish(work):
    """Upload the reviewed background as a separate document."""
    work = work.resolve()
    display(work, workflow.publish(work))


@migration.command()
@click.argument("work", type=click.Path(exists=True, file_okay=False, path_type=Path))
@guarded
def resume(work):
    """Attach native handwriting after the tablet initializes pages."""
    work = work.resolve()
    display(work, workflow.resume(work))


@migration.command()
@click.argument("work", type=click.Path(exists=True, file_okay=False, path_type=Path))
@guarded
def status(work):
    """Show the saved migration stage without contacting the cloud."""
    work = work.resolve()
    display(work, workflow.load(work))
