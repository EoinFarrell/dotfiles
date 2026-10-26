"""Tests for build_skills.py. Run: python3 -m unittest scripts/test_build_skills.py

Upstream repos are real local git repos cloned through a file:// URL template,
so the clone/overlay/rename path runs end to end without network access.
"""
import json
import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

import build_skills

try:
    import yaml  # noqa: F401
    HAS_YAML = True
except ImportError:
    try:
        import ruamel.yaml  # noqa: F401
        HAS_YAML = True
    except ImportError:
        HAS_YAML = False

GIT_ENV = {
    **os.environ,
    "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
    "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t",
}

SKILL = textwrap.dedent("""\
    ---
    name: tdd
    description: test first
    ---
    name: not frontmatter
    body
    """)


def git(cwd, *args):
    return subprocess.run(["git", *args], cwd=cwd, check=True, env=GIT_ENV,
                          capture_output=True, text=True).stdout


class BuildSkillsTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.tmp = Path(self._tmp.name)
        self.upstream = self.tmp / "upstream"  # <owner>/<repo> bare-ish source repos
        self.clones = self.tmp / "clones"
        self.out = self.tmp / "out"
        self.overlays = self.tmp / "overlays"
        self.overlays.mkdir()
        self.url_template = f"file://{self.upstream}/{{name}}"

    def make_upstream(self, name, files):
        repo = self.upstream / name
        for rel, content in files.items():
            path = repo / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        git(repo, "init", "-q", "-b", "main")
        git(repo, "add", "-A")
        git(repo, "commit", "-qm", "init")
        return repo

    def build(self, repos, **kw):
        return build_skills.build(
            repos, clone_root=self.clones, out_dir=self.out,
            overlays_dir=self.overlays, url_template=self.url_template, **kw)

    def test_rewrite_skill_name_only_touches_frontmatter(self):
        self.assertEqual(
            build_skills.rewrite_skill_name(SKILL, "matt-tdd"),
            SKILL.replace("name: tdd", "name: matt-tdd", 1))

    def test_rewrite_skill_name_without_name_is_unchanged(self):
        text = "---\ndescription: x\n---\nbody\n"
        self.assertEqual(build_skills.rewrite_skill_name(text, "matt-tdd"), text)

    def test_builds_prefixed_copy_with_renamed_frontmatter(self):
        self.make_upstream("o/skills", {
            "skills/eng/tdd/SKILL.md": SKILL,
            "skills/eng/tdd/refs/a.md": "ref",
        })
        result = self.build([{"name": "o/skills", "prefix": "matt",
                              "skills": ["skills/eng/tdd"]}])
        self.assertEqual(result.failures, [])
        built = self.out / "matt-tdd"
        self.assertIn("name: matt-tdd\n", (built / "SKILL.md").read_text())
        self.assertEqual((built / "refs/a.md").read_text(), "ref")

    def test_overlay_is_applied(self):
        repo = self.make_upstream("o/skills", {"s/tdd/SKILL.md": SKILL})
        (repo / "s/tdd/SKILL.md").write_text(SKILL + "extra\n")
        patch = git(repo / "s/tdd", "diff", "--relative")
        git(repo, "checkout", "-q", "--", ".")
        (self.overlays / "tdd.patch").write_text(patch)
        self.build([{"name": "o/skills", "prefix": "matt", "skills": ["s/tdd"]}])
        self.assertTrue((self.out / "matt-tdd/SKILL.md").read_text().endswith("extra\n"))

    def test_overlay_build_dir_gets_unprefixed_copy_for_overlaid_skills_only(self):
        repo = self.make_upstream("o/skills", {
            "s/tdd/SKILL.md": SKILL, "s/other/SKILL.md": SKILL.replace("tdd", "other")})
        (repo / "s/tdd/SKILL.md").write_text(SKILL + "extra\n")
        (self.overlays / "tdd.patch").write_text(git(repo / "s/tdd", "diff", "--relative"))
        git(repo, "checkout", "-q", "--", ".")
        overlay_build = self.tmp / "build"
        result = self.build([{"name": "o/skills", "prefix": "matt",
                              "skills": ["s/tdd", "s/other"]}],
                            overlay_build_dir=overlay_build)
        # Patched but not yet renamed: the playbook's contract for ~/Code/claude/.build.
        self.assertIn("name: tdd\n", (overlay_build / "tdd/SKILL.md").read_text())
        self.assertTrue((overlay_build / "tdd/SKILL.md").read_text().endswith("extra\n"))
        self.assertFalse((overlay_build / "other").exists())
        self.assertEqual(result.overlaid, [
            {"basename": "tdd", "dest_name": "matt-tdd", "build_dir": str(overlay_build / "tdd")}])

    def test_report_is_json_serialisable(self):
        self.make_upstream("o/skills", {"s/tdd/SKILL.md": SKILL})
        (self.overlays / "tdd.patch").write_text("diff --git a/SKILL.md b/SKILL.md\n"
                                                 "--- a/SKILL.md\n+++ b/SKILL.md\n"
                                                 "@@ -1 +1 @@\n-nope\n+yes\n")
        result = self.build([{"name": "o/skills", "prefix": "matt", "skills": ["s/tdd"]}])
        report = json.loads(json.dumps(build_skills.report(result)))
        self.assertEqual(report["failures"][0]["basename"], "tdd")
        self.assertEqual(set(report), {"built", "skipped", "pruned", "overlays", "failures"})

    def test_drifted_overlay_is_reported_and_leaves_previous_build(self):
        self.make_upstream("o/skills", {
            "s/tdd/SKILL.md": SKILL, "s/other/SKILL.md": SKILL.replace("tdd", "other")})
        (self.overlays / "tdd.patch").write_text(textwrap.dedent("""\
            diff --git a/SKILL.md b/SKILL.md
            --- a/SKILL.md
            +++ b/SKILL.md
            @@ -1,3 +1,3 @@
             ---
            -name: something else entirely
            +name: x
             description: nope
            """))
        (self.out / "matt-tdd").mkdir(parents=True)
        (self.out / "matt-tdd/SKILL.md").write_text("previous")
        result = self.build([{"name": "o/skills", "prefix": "matt",
                              "skills": ["s/tdd", "s/other"]}])
        self.assertEqual([f.basename for f in result.failures], ["tdd"])
        self.assertEqual((self.out / "matt-tdd/SKILL.md").read_text(), "previous")
        self.assertTrue((self.out / "matt-other/SKILL.md").exists())

    def test_skill_without_skill_md_is_skipped(self):
        self.make_upstream("o/skills", {"s/empty/README.md": "x"})
        result = self.build([{"name": "o/skills", "prefix": "matt",
                              "skills": ["s/empty"]}])
        self.assertEqual(result.skipped, ["matt-empty"])
        self.assertFalse((self.out / "matt-empty").exists())

    def test_prunes_stale_skills_but_not_unrelated_dirs(self):
        self.make_upstream("o/skills", {"s/tdd/SKILL.md": SKILL})
        (self.out / "old-skill").mkdir(parents=True)
        (self.out / "old-skill/SKILL.md").write_text("stale")
        (self.out / "notes").mkdir()
        (self.out / "notes/README.md").write_text("keep")
        self.build([{"name": "o/skills", "prefix": "matt", "skills": ["s/tdd"]}])
        self.assertFalse((self.out / "old-skill").exists())
        self.assertTrue((self.out / "notes/README.md").exists())

    def test_existing_clone_is_not_updated_unless_asked(self):
        repo = self.make_upstream("o/skills", {"s/tdd/SKILL.md": SKILL})
        repos = [{"name": "o/skills", "prefix": "matt", "skills": ["s/tdd"]}]
        self.build(repos)
        (repo / "s/tdd/SKILL.md").write_text(SKILL + "new\n")
        git(repo, "commit", "-qam", "bump")
        self.build(repos)
        self.assertNotIn("new", (self.out / "matt-tdd/SKILL.md").read_text())
        self.build(repos, update=True)
        self.assertIn("new", (self.out / "matt-tdd/SKILL.md").read_text())

    @unittest.skipUnless(HAS_YAML, "needs PyYAML or ruamel.yaml")
    def test_load_repos_reads_the_ansible_vars_file(self):
        path = self.tmp / "repos.yaml"
        path.write_text("---\nclaude_skill_repos:\n  - name: o/r\n    prefix: p\n"
                        "    skills:\n      - a/b\n")
        self.assertEqual(build_skills.load_repos(path),
                         [{"name": "o/r", "prefix": "p", "skills": ["a/b"]}])


if __name__ == "__main__":
    unittest.main()
