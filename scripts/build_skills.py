#!/usr/bin/env python3
"""Build a flat directory of prefixed, overlay-patched agent skills.

Mirrors what ansible/git_setup.yaml does for the laptop's ~/.claude/skills
(clone upstream repos, apply claude/skill-overlays/<basename>.patch, rewrite
SKILL.md `name:` to <prefix>-<basename>), but with no Ansible, so it can run
where Ansible isn't available, e.g. in the Hermes container, to feed
`skills.external_dirs`. Reads the same ansible/vars/claude_skill_repos.yaml.

Standard library plus git, and PyYAML or ruamel.yaml for the repo list (the
Hermes image ships ruamel.yaml). Repos are cloned once and only updated with
--update, matching the playbook's `update: no`. Exits 1 if an overlay no
longer applies; that skill's previous build is left untouched.
"""
import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_URL_TEMPLATE = "https://github.com/{name}.git"


@dataclass
class OverlayFailure:
    basename: str
    patch: Path
    error: str


@dataclass
class Result:
    built: list = field(default_factory=list)
    skipped: list = field(default_factory=list)
    pruned: list = field(default_factory=list)
    failures: list = field(default_factory=list)


def load_repos(path):
    text = Path(path).read_text()
    try:
        import yaml
        data = yaml.safe_load(text)
    except ImportError:
        try:
            from ruamel.yaml import YAML
        except ImportError:
            sys.exit("need PyYAML or ruamel.yaml to read " + str(path))
        data = YAML(typ="safe").load(text)
    return data["claude_skill_repos"]


def rewrite_skill_name(text, name):
    """Set `name:` in the leading frontmatter block; leave the body alone."""
    m = re.match(r"(---\n)(.*?\n)(---\n)", text, re.DOTALL)
    if not m:
        return text
    front, n = re.subn(r"^name:.*$", f"name: {name}", m.group(2), count=1, flags=re.MULTILINE)
    return text if n == 0 else m.group(1) + front + m.group(3) + text[m.end():]


def _git(*args, cwd=None):
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)


def _ensure_clone(name, clone_root, url_template, update):
    dest = Path(clone_root) / name
    if not dest.exists():
        dest.parent.mkdir(parents=True, exist_ok=True)
        r = _git("clone", "-q", url_template.format(name=name), str(dest))
        if r.returncode:
            sys.exit(f"clone {name} failed: {r.stderr.strip()}")
    elif update:
        r = _git("pull", "-q", "--ff-only", cwd=dest)
        if r.returncode:
            sys.exit(f"update {name} failed: {r.stderr.strip()}")
    return dest


def _replace_dir(staged, dest):
    if dest.exists():
        shutil.rmtree(dest)
    shutil.move(str(staged), str(dest))


def build(repos, clone_root, out_dir, overlays_dir, url_template=DEFAULT_URL_TEMPLATE,
          update=False):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    result = Result()
    expected = set()
    with tempfile.TemporaryDirectory(dir=out_dir.parent) as stage_root:
        for repo in repos:
            clone = _ensure_clone(repo["name"], clone_root, url_template, update)
            for skill in repo["skills"]:
                basename = Path(skill).name
                dest_name = f"{repo['prefix']}-{basename}"
                expected.add(dest_name)
                src = clone / skill
                if not (src / "SKILL.md").is_file():
                    shutil.rmtree(out_dir / dest_name, ignore_errors=True)
                    result.skipped.append(dest_name)
                    continue
                staged = Path(stage_root) / dest_name
                shutil.copytree(src, staged)
                patch = Path(overlays_dir) / f"{basename}.patch"
                if patch.is_file():
                    r = _git("apply", str(patch.resolve()), cwd=staged)
                    if r.returncode:
                        result.failures.append(OverlayFailure(basename, patch, r.stderr.strip()))
                        continue
                skill_md = staged / "SKILL.md"
                skill_md.write_text(rewrite_skill_name(skill_md.read_text(), dest_name))
                _replace_dir(staged, out_dir / dest_name)
                result.built.append(dest_name)
    # A failed overlay keeps its previous build, so count it as still expected.
    for entry in sorted(out_dir.iterdir()):
        if entry.is_dir() and entry.name not in expected and (entry / "SKILL.md").is_file():
            shutil.rmtree(entry)
            result.pruned.append(entry.name)
    return result


def main(argv=None):
    here = Path(__file__).resolve().parent
    root = here.parent
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("--repos-file", default=root / "ansible/vars/claude_skill_repos.yaml")
    p.add_argument("--overlays-dir", default=root / "claude/skill-overlays")
    p.add_argument("--clone-root", required=True, help="where upstream repos are cloned")
    p.add_argument("--out", required=True, help="output dir; its skill dirs are managed here")
    p.add_argument("--url-template", default=DEFAULT_URL_TEMPLATE)
    p.add_argument("--update", action="store_true", help="git pull --ff-only existing clones")
    args = p.parse_args(argv)

    result = build(load_repos(args.repos_file), args.clone_root, args.out,
                   args.overlays_dir, args.url_template, args.update)
    print(f"built {len(result.built)}, skipped {len(result.skipped)}, "
          f"pruned {len(result.pruned)}, failed {len(result.failures)}")
    for name in result.skipped:
        print(f"skipped {name}: no SKILL.md")
    for f in result.failures:
        print(f"overlay failed for {f.basename} ({f.patch}): {f.error}", file=sys.stderr)
    return 1 if result.failures else 0


if __name__ == "__main__":
    sys.exit(main())
