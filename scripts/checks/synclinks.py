#!/usr/bin/env python3
import os
import subprocess
import sys
from collections import deque
from pathlib import Path


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", *args])


def read_index(root: Path) -> tuple[set[Path], set[Path], dict[Path, str]]:
    files: set[Path] = set()
    directories = {root}
    links: dict[Path, str] = {}
    for record in git("ls-files", "--stage", "-z").split(b"\0"):
        if not record:
            continue
        metadata, name = record.split(b"\t", 1)
        mode, object_id, stage = metadata.split()
        if stage != b"0":
            raise ValueError("Resolve staged merge conflicts before checking symlinks.")
        path = root / os.fsdecode(name)
        files.add(path)
        parent = path.parent
        while parent != root:
            directories.add(parent)
            parent = parent.parent
        if mode == b"120000":
            links[path] = os.fsdecode(git("cat-file", "blob", object_id.decode()))
        elif mode == b"160000":
            directories.add(path)
    return files, directories, links


def resolves(
    path: Path,
    root: Path,
    files: set[Path],
    directories: set[Path],
    links: dict[Path, str],
) -> bool:
    pending = deque(path.parts[1:])
    current = Path(path.anchor)
    followed = 0
    while pending:
        part = pending.popleft()
        if part in ("", "."):
            continue
        if part == "..":
            current = current.parent
            continue
        current /= part
        internal = current.is_relative_to(root)
        target = links.get(current) if internal else None
        if not internal and current.is_symlink():
            target = os.readlink(current)
        if target is not None:
            followed += 1
            if followed > 40 or not target or "\0" in target:
                return False
            current = Path("/") if target.startswith("/") else current.parent
            pending.extendleft(reversed(target.split("/")))
            continue
        is_directory = current in directories if internal else current.is_dir()
        exists = current in files or is_directory if internal else current.exists()
        if not exists or (pending and not is_directory):
            return False
    return True


def main() -> int:
    try:
        root = Path(os.fsdecode(git("rev-parse", "--show-toplevel")).rstrip("\n"))
        os.chdir(root)
        files, directories, links = read_index(root)
        broken = [
            path
            for path in links
            if not resolves(path, root, files, directories, links)
        ]
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f"Cannot check symlinks: {error}", file=sys.stderr)
        return 1
    for path in broken:
        print(
            f"Broken staged symlink: {str(path.relative_to(root))!r}"
            f" -> {links[path]!r}",
            file=sys.stderr,
        )
    return int(bool(broken))


if __name__ == "__main__":
    sys.exit(main())
