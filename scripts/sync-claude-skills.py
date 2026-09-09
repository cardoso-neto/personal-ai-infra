#!/usr/bin/env python3

import os
import sys
from pathlib import Path


def discover_skills(source: Path) -> dict[str, Path]:
    if not source.is_dir():
        raise ValueError(f"Missing skills directory: {source}")
    skills: dict[str, Path] = {}
    names: dict[str, Path] = {}
    for directory, folders, files in os.walk(source):
        folders.sort()
        if not any(name.lower() == "skill.md" for name in files):
            continue
        skill = Path(directory)
        key = skill.name.casefold()
        if key in names:
            raise ValueError(f"Duplicate skill name: {names[key]} and {skill}")
        if key == "synced":
            raise ValueError(f"Claude reserves the skill folder name 'synced': {skill}")
        names[key] = skill
        skills[skill.name] = skill
    return skills


def managed_link(link: Path, source: Path) -> bool:
    if not link.is_symlink():
        return False
    target = Path(os.path.abspath(link.parent / link.readlink()))
    return target.is_relative_to(source)


def sync_skills(root: Path) -> None:
    source = root / ".agents/skills"
    destination = root / ".claude/skills"
    skills = discover_skills(source)
    migrate = destination.is_symlink()
    if migrate and destination.resolve() != source.resolve():
        raise ValueError(f"Refusing to replace unrelated symlink: {destination}")
    if not migrate and destination.exists() and not destination.is_dir():
        raise ValueError(f"Expected a directory: {destination}")
    existing = (
        list(destination.iterdir()) if destination.is_dir() and not migrate else []
    )
    for entry in existing:
        if entry.name.casefold() in {name.casefold() for name in skills}:
            if not managed_link(entry, source):
                raise ValueError(f"Refusing to replace unmanaged entry: {entry}")
    if migrate:
        destination.unlink()
    destination.mkdir(parents=True, exist_ok=True)
    for entry in existing:
        if managed_link(entry, source) and entry.name not in skills:
            entry.unlink()
    for name, skill in skills.items():
        link = destination / name
        target = Path(os.path.relpath(skill, destination))
        if link.is_symlink() and link.readlink() == target:
            continue
        if link.is_symlink():
            link.unlink()
        link.symlink_to(target, target_is_directory=True)
    print(f"Synced {len(skills)} Claude skill links.")


def main() -> int:
    try:
        sync_skills(Path(__file__).resolve().parent.parent)
    except (OSError, ValueError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
