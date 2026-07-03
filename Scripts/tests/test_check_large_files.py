from __future__ import annotations

import contextlib
import io
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPTS_DIRECTORY = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS_DIRECTORY))

import check_large_files  # noqa: E402


class LargeFilePolicyTests(unittest.TestCase):
    def make_repo(self) -> Path:
        directory = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, directory)
        subprocess.run(["git", "init"], cwd=directory, check=True, stdout=subprocess.PIPE)
        subprocess.run(
            ["git", "config", "user.email", "tests@example.com"],
            cwd=directory,
            check=True,
        )
        subprocess.run(
            ["git", "config", "user.name", "Tests"],
            cwd=directory,
            check=True,
        )
        return directory

    def add_all_without_lfs_filter(self, repo: Path) -> None:
        for path in sorted(repo.rglob("*")):
            if path.is_dir() or ".git" in path.parts:
                continue
            relative_path = path.relative_to(repo).as_posix()
            object_id = subprocess.run(
                ["git", "hash-object", "-w", "--stdin"],
                cwd=repo,
                input=path.read_bytes(),
                stdout=subprocess.PIPE,
                check=True,
            ).stdout.decode("utf-8").strip()
            subprocess.run(
                [
                    "git",
                    "update-index",
                    "--add",
                    "--cacheinfo",
                    f"100644,{object_id},{relative_path}",
                ],
                cwd=repo,
                check=True,
            )

    def run_policy(self, repo: Path, limit: int) -> tuple[int, str]:
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = check_large_files.main(
                ["--repo", str(repo), "--limit-bytes", str(limit)]
            )
        return exit_code, stdout.getvalue()

    def test_large_plain_git_file_fails(self) -> None:
        repo = self.make_repo()
        asset = repo / "Weights" / "model.bin"
        asset.parent.mkdir()
        asset.write_bytes(b"x" * 2048)
        self.add_all_without_lfs_filter(repo)

        exit_code, output = self.run_policy(repo, 1024)

        self.assertEqual(exit_code, 1)
        self.assertIn("plain Git", output)
        self.assertIn("Weights/model.bin", output)

    def test_large_lfs_attributed_file_passes(self) -> None:
        repo = self.make_repo()
        (repo / ".gitattributes").write_text(
            "*.bin filter=lfs diff=lfs merge=lfs -text\n"
        )
        asset = repo / "Weights" / "model.bin"
        asset.parent.mkdir()
        asset.write_bytes(b"x" * 2048)
        self.add_all_without_lfs_filter(repo)

        exit_code, output = self.run_policy(repo, 1024)

        self.assertEqual(exit_code, 0)
        self.assertIn("LFS", output)
        self.assertIn("Large-file policy passed", output)

    def test_small_plain_git_file_passes(self) -> None:
        repo = self.make_repo()
        (repo / "README.md").write_text("small\n")
        self.add_all_without_lfs_filter(repo)

        exit_code, output = self.run_policy(repo, 1024)

        self.assertEqual(exit_code, 0)
        self.assertIn("No tracked files over", output)


if __name__ == "__main__":
    unittest.main()
