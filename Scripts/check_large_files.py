from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


DEFAULT_LIMIT_BYTES = 10 * 1024 * 1024


@dataclass(frozen=True)
class TrackedFile:
    path: str
    size: int
    lfs_attributed: bool


def run_git(repo: Path, args: list[str], *, stdin: bytes | None = None) -> bytes:
    result = subprocess.run(
        ["git", *args],
        cwd=repo,
        input=stdin,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        stderr = result.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(f"git {' '.join(args)} failed: {stderr}")
    return result.stdout


def repository_root(path: Path) -> Path:
    output = run_git(path, ["rev-parse", "--show-toplevel"])
    return Path(output.decode("utf-8").strip())


def tracked_paths(repo: Path) -> list[str]:
    output = run_git(repo, ["ls-files", "-z"])
    return [item.decode("utf-8") for item in output.split(b"\0") if item]


def chunked(items: list[str], count: int) -> list[list[str]]:
    return [items[index : index + count] for index in range(0, len(items), count)]


def lfs_attributed_paths(repo: Path, paths: list[str]) -> set[str]:
    attributed: set[str] = set()
    for chunk in chunked(paths, 200):
        output = run_git(repo, ["check-attr", "-z", "filter", "--", *chunk])
        fields = [item.decode("utf-8") for item in output.split(b"\0") if item]
        for index in range(0, len(fields), 3):
            path, attribute, value = fields[index : index + 3]
            if attribute == "filter" and value == "lfs":
                attributed.add(path)
    return attributed


def collect_tracked_files(repo: Path) -> list[TrackedFile]:
    paths = tracked_paths(repo)
    lfs_paths = lfs_attributed_paths(repo, paths)
    files: list[TrackedFile] = []
    for path in paths:
        absolute_path = repo / path
        if not absolute_path.is_file():
            continue
        files.append(
            TrackedFile(
                path=path,
                size=absolute_path.stat().st_size,
                lfs_attributed=path in lfs_paths,
            )
        )
    return files


def format_size(size: int) -> str:
    for unit in ("bytes", "KiB", "MiB", "GiB"):
        if size < 1024 or unit == "GiB":
            if unit == "bytes":
                return f"{size} {unit}"
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} GiB"


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Fail if tracked files above the size limit are not covered by Git LFS."
        )
    )
    parser.add_argument(
        "--repo",
        type=Path,
        default=Path.cwd(),
        help="Repository path to inspect. Defaults to the current directory.",
    )
    parser.add_argument(
        "--limit-bytes",
        type=int,
        default=DEFAULT_LIMIT_BYTES,
        help=f"Tracked-file size limit before LFS is required. Default: {DEFAULT_LIMIT_BYTES}.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    repo = repository_root(args.repo.resolve())
    tracked = collect_tracked_files(repo)
    large_files = sorted(
        (item for item in tracked if item.size > args.limit_bytes),
        key=lambda item: item.size,
        reverse=True,
    )
    violations = [item for item in large_files if not item.lfs_attributed]

    if large_files:
        print(f"Tracked files over {format_size(args.limit_bytes)}:")
        for item in large_files:
            status = "LFS" if item.lfs_attributed else "plain Git"
            print(f"  {status:9} {format_size(item.size):>10}  {item.path}")
    else:
        print(f"No tracked files over {format_size(args.limit_bytes)}.")

    if violations:
        print()
        for item in violations:
            print(
                "::error "
                f"file={item.path}::Tracked file is {format_size(item.size)} "
                "but is not covered by Git LFS attributes."
            )
        print(
            "\nMove the asset outside the repository, or add an intentional Git LFS "
            "rule before committing it."
        )
        return 1

    print("Large-file policy passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
