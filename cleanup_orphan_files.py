#!/usr/bin/env python3
"""
cleanup_orphan_files.py

Reads all Stata PKG files from stata-pkg-files/, builds the set of files
that are referenced in at least one PKG file, then compares against the
files listed in sscfiles.txt. Files present in sscfiles.txt but NOT
referenced in any PKG file (and not PKG or TOC files themselves) are
reported and optionally deleted from the fmwww.bc.edu/ directory.

Usage:
    python3 cleanup_orphan_files.py [--delete] [--verbose]

Options:
    --delete   Actually delete the orphan files (default: dry-run only)
    --verbose  Print each file being processed
"""

import os
import sys
import argparse
import posixpath
from pathlib import Path
from typing import Set, Tuple

BASE_DIR = Path(__file__).parent
PKG_DIR = BASE_DIR / "stata-pkg-files"
SSCFILES = BASE_DIR / "sscfiles.txt"
FMWWW_DIR = BASE_DIR / "fmwww.bc.edu"


def parse_pkg_file(pkg_path: Path, pkg_root: Path) -> Set[str]:
    """
    Parse a PKG file and return the set of file paths it references.

    pkg_path : absolute path to the .pkg file inside stata-pkg-files/
    pkg_root : the stata-pkg-files/ root (used to compute relative paths)

    Each 'f <filename>' line in the PKG file names a file relative to
    the directory containing the PKG file.  Paths such as '../e/foo.ado'
    are resolved with posixpath so that the result is a clean relative
    path rooted at pkg_root (i.e. starting with 'fmwww.bc.edu/...').
    """
    referenced = set()

    # Directory containing this PKG file, relative to pkg_root
    pkg_rel_dir = pkg_path.parent.relative_to(pkg_root).as_posix()

    try:
        text = pkg_path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        print(f"WARNING: cannot read {pkg_path}: {exc}", file=sys.stderr)
        return referenced

    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("f "):
            continue
        # Everything after the leading 'f ' is the filename (may contain spaces)
        fname = line[2:].strip()
        if not fname:
            continue
        # Resolve relative to the PKG file's directory
        resolved = posixpath.normpath(posixpath.join(pkg_rel_dir, fname))
        referenced.add(resolved)

    return referenced


def build_pkg_referenced_files(verbose: bool = False) -> Tuple[Set[str], Set[str]]:
    """
    Walk stata-pkg-files/ and collect:
      - all files referenced by 'f' lines  (referenced_files)
      - all PKG file paths themselves       (pkg_files)

    Both sets contain paths relative to the stata-pkg-files/ root,
    i.e. strings like 'fmwww.bc.edu/repec/bocode/a/actest.ado'.
    """
    referenced_files: Set[str] = set()
    pkg_files: Set[str] = set()

    pkg_root = PKG_DIR

    for pkg_path in sorted(pkg_root.rglob("*.pkg")):
        rel = pkg_path.relative_to(pkg_root).as_posix()
        pkg_files.add(rel)
        if verbose:
            print(f"  parsing {rel}")
        refs = parse_pkg_file(pkg_path, pkg_root)
        referenced_files.update(refs)

    return referenced_files, pkg_files


def read_sscfiles() -> Set[str]:
    """Return the set of paths listed in sscfiles.txt (one per line)."""
    paths = set()
    with SSCFILES.open(encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                paths.add(line)
    return paths


def main():
    parser = argparse.ArgumentParser(
        description="Remove files from fmwww.bc.edu/ that are not listed in any PKG file."
    )
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Actually delete orphan files (default: dry-run, only report).",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print each PKG file as it is parsed.",
    )
    args = parser.parse_args()

    # ------------------------------------------------------------------ #
    # 1. Collect files referenced across all PKG files
    # ------------------------------------------------------------------ #
    print("Parsing PKG files …", flush=True)
    referenced_files, pkg_files = build_pkg_referenced_files(verbose=args.verbose)
    print(f"  {len(pkg_files):,} PKG files found")
    print(f"  {len(referenced_files):,} unique file references across all PKG files")

    # ------------------------------------------------------------------ #
    # 2. Build the 'keep' set
    #    - files referenced by an 'f' line in any PKG file
    #    - the PKG files themselves  (needed as package manifests)
    #    - .toc files                (needed as repository index)
    # ------------------------------------------------------------------ #
    keep: Set[str] = set()
    keep.update(referenced_files)
    keep.update(pkg_files)

    # ------------------------------------------------------------------ #
    # 3. Read sscfiles.txt
    # ------------------------------------------------------------------ #
    print("Reading sscfiles.txt …", flush=True)
    ssc_files = read_sscfiles()
    print(f"  {len(ssc_files):,} files listed in sscfiles.txt")

    # ------------------------------------------------------------------ #
    # 4. Find orphans (in sscfiles.txt but not in keep set)
    #    Treat .toc files as always-keep infrastructure
    # ------------------------------------------------------------------ #
    orphans = sorted(
        f for f in ssc_files
        if f not in keep and not f.endswith(".toc")
    )

    print(f"\n{len(orphans):,} orphan files (present in sscfiles.txt, not in any PKG):")

    if not orphans:
        print("  Nothing to do.")
        return

    for path in orphans:
        print(f"  {path}")

    # ------------------------------------------------------------------ #
    # 5. Delete (or dry-run)
    # ------------------------------------------------------------------ #
    if not args.delete:
        print(
            f"\nDry-run complete. Re-run with --delete to remove {len(orphans):,} files."
        )
        return

    print(f"\nDeleting {len(orphans):,} orphan files …")
    deleted = 0
    missing = 0
    errors = 0

    for rel_path in orphans:
        abs_path = BASE_DIR / rel_path
        if not abs_path.exists():
            missing += 1
            print(f"  MISSING (skip): {rel_path}", file=sys.stderr)
            continue
        try:
            abs_path.unlink()
            deleted += 1
            if args.verbose:
                print(f"  deleted: {rel_path}")
        except OSError as exc:
            errors += 1
            print(f"  ERROR deleting {rel_path}: {exc}", file=sys.stderr)

    print(f"\nDone: {deleted:,} deleted, {missing:,} already missing, {errors:,} errors.")


if __name__ == "__main__":
    main()
