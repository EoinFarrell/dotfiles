#!/usr/bin/env python3
"""Idempotently merge a Claude Code hooks fragment into ~/.claude/settings.json.

~/.claude/settings.json is a real, machine-local file (permissions, model,
statusLine...), not a symlink into this repo, so it can't be managed by
ansible's link engine. Instead the repo keeps a fragment of just the hooks it
owns (e.g. claude/tmux-agent-indicator-hooks.json) and this script folds it in.

Entries are matched by --marker: any existing hook command containing the
marker is dropped before the fragment's entries are appended, so reruns (and
upstream command changes) never duplicate hooks. Unrelated hooks and every
other key are left alone. Prints "changed" or "unchanged" on stdout.
"""
import argparse
import json
import sys
from pathlib import Path


def merge(settings: dict, fragment: dict, marker: str) -> dict:
    hooks = settings.setdefault("hooks", {})
    for event, entries in fragment.get("hooks", {}).items():
        kept = []
        for entry in hooks.get(event, []):
            commands = [h.get("command", "") for h in entry.get("hooks", [])]
            if not any(marker in c for c in commands):
                kept.append(entry)
        hooks[event] = kept + entries
    return settings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fragment", required=True, type=Path)
    parser.add_argument("--settings", default=Path.home() / ".claude/settings.json", type=Path)
    parser.add_argument("--marker", required=True, help="substring identifying our hook commands")
    args = parser.parse_args()

    fragment = json.loads(args.fragment.read_text())
    original = json.loads(args.settings.read_text()) if args.settings.exists() else {}
    merged = merge(json.loads(json.dumps(original)), fragment, args.marker)

    if merged == original:
        print("unchanged")
        return 0

    args.settings.parent.mkdir(parents=True, exist_ok=True)
    if args.settings.exists():
        args.settings.with_suffix(".json.bak").write_text(args.settings.read_text())
    args.settings.write_text(json.dumps(merged, indent=2) + "\n")
    print("changed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
