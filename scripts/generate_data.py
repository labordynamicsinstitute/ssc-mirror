#!/usr/bin/env python3
"""
generate_data.py

Generates two JSON data files for the SSC Mirror website:

  1. docs/data/packages.json   – list of all packages parsed from .pkg files
  2. docs/data/tags.json       – list of all tags + contiguous-range metadata

Usage (from repository root):
    python scripts/generate_data.py \
        --pkg-dir  <path-to-releases-branch>/fmwww.bc.edu/repec/bocode \
        --out-dir  docs/data \
        --repo     labordynamicsinstitute/ssc-mirror
"""

import argparse
import json
import os
import re
import sys
from datetime import date
from pathlib import Path

try:
    import requests
except ImportError:
    requests = None


# ---------------------------------------------------------------------------
# PKG parsing
# ---------------------------------------------------------------------------

def parse_pkg_file(path: Path) -> dict:
    """Parse a Stata/REPEC .pkg file and return a metadata dict."""
    pkg = {
        "name": path.stem.upper(),
        "description": "",
        "author": "",
        "distribution_date": "",
        "keywords": [],
    }
    try:
        with open(path, "r", encoding="latin-1", errors="replace") as fh:
            content = fh.read()
    except OSError:
        return pkg

    lines = content.splitlines()
    desc_lines = []
    # Patterns that indicate a metadata line, not description text
    meta_prefixes = ("KW:", "Requires:", "Distribution-Date:", "Author:",
                     "Support:", "Also see:", "SJ-")

    first_d_seen = False
    for line in lines:
        stripped = line.rstrip("\r\n")
        if stripped.startswith("d '"):
            # First 'd' line: package title  →  d 'PKGNAME': ...title...
            m = re.match(r"d '([^']+)'[:\s]*(.*)", stripped)
            if m:
                pkg["name"] = m.group(1).strip()
                title = m.group(2).strip()
                if title:
                    desc_lines.append(title)
            first_d_seen = True
        elif first_d_seen and re.match(r"^d(\s|$)", stripped):
            # Description or metadata continuation line
            text = stripped[1:].strip()
            if not text:
                continue
            if any(text.startswith(p) for p in meta_prefixes):
                continue
            desc_lines.append(text)
        elif stripped.startswith("f ") or stripped.startswith("e "):
            break  # reached file listing section

    # Extract structured metadata via regex on full content
    m = re.search(r"^d\s+Author:\s*(.+)$", content, re.MULTILINE)
    if m:
        pkg["author"] = m.group(1).split(",")[0].strip()

    m = re.search(r"^d\s+Distribution-Date:\s*(\S+)", content, re.MULTILINE)
    if m:
        pkg["distribution_date"] = m.group(1).strip()

    m_kw = re.findall(r"^d\s+KW:\s*(.+)$", content, re.MULTILINE)
    pkg["keywords"] = [k.strip() for k in m_kw if k.strip()]

    # Join and normalise description
    description = " ".join(desc_lines).strip()
    pkg["description"] = description[:300]  # cap at 300 chars for display

    return pkg


def collect_packages(bocode_dir: Path) -> list:
    """Walk bocode directory tree and parse all .pkg files."""
    packages = []
    for pkg_file in sorted(bocode_dir.rglob("*.pkg")):
        pkg = parse_pkg_file(pkg_file)
        packages.append(pkg)
    return packages


# ---------------------------------------------------------------------------
# Tags / ranges
# ---------------------------------------------------------------------------

def fetch_tags_via_api(repo: str, token: str = None) -> list:
    """
    Fetch all tags from the GitHub API for *repo* (e.g. 'owner/name').
    Returns a sorted list of tag name strings (oldest first).
    Only date-looking tags (YYYY-MM-DD) are returned.
    """
    if requests is None:
        print("WARNING: 'requests' package not available – cannot fetch tags via API.")
        return []

    headers = {"Accept": "application/vnd.github+json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    tags = []
    page = 1
    while True:
        url = f"https://api.github.com/repos/{repo}/tags?per_page=100&page={page}"
        resp = requests.get(url, headers=headers, timeout=30)
        if resp.status_code != 200:
            print(f"WARNING: GitHub API returned {resp.status_code} for tags (page {page}). "
                  f"Message: {resp.text[:200]}")
            break
        data = resp.json()
        if not data:
            break
        tags.extend(data)
        if len(data) < 100:
            break
        page += 1

    # Filter to date-format tags only
    date_re = re.compile(r"^\d{4}-\d{2}-\d{2}[a-z]?$")
    tag_names = [t["name"] for t in tags if date_re.match(t["name"])]
    # Sort ascending
    tag_names.sort()
    return tag_names


def compute_ranges(tag_names: list) -> list:
    """
    Given a sorted list of date-format tag names, compute contiguous ranges.

    A range is a maximal sequence of consecutive calendar dates (each having
    at least one tag). Suffixed tags like '2021-12-23a' are mapped to their
    base date for continuity purposes.

    Returns a list of dicts:
        {start: str, end: str, count: int, tags_list: [str]}
    """
    if not tag_names:
        return []

    # Map base-date → list of tags
    date_re = re.compile(r"^(\d{4}-\d{2}-\d{2})")
    date_map: dict[str, list] = {}
    for tag in tag_names:
        m = date_re.match(tag)
        if m:
            base = m.group(1)
            date_map.setdefault(base, []).append(tag)

    sorted_dates = sorted(date_map.keys())
    if not sorted_dates:
        return []

    ranges = []
    range_start = sorted_dates[0]
    range_end = sorted_dates[0]
    range_tags: list[str] = list(date_map[sorted_dates[0]])

    for d in sorted_dates[1:]:
        prev_date = date.fromisoformat(range_end)
        curr_date = date.fromisoformat(d)
        if (curr_date - prev_date).days == 1:
            # Contiguous
            range_end = d
            range_tags.extend(date_map[d])
        else:
            ranges.append({
                "start": range_start,
                "end": range_end,
                "count": len(range_tags),
                "tags_list": range_tags,
            })
            range_start = d
            range_end = d
            range_tags = list(date_map[d])

    ranges.append({
        "start": range_start,
        "end": range_end,
        "count": len(range_tags),
        "tags_list": range_tags,
    })

    return ranges


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Generate JSON data files for SSC Mirror website")
    parser.add_argument(
        "--pkg-dir",
        required=True,
        help="Path to fmwww.bc.edu/repec/bocode directory from the releases branch",
    )
    parser.add_argument(
        "--out-dir",
        required=True,
        help="Output directory for generated JSON files (e.g. docs/data)",
    )
    parser.add_argument(
        "--repo",
        default="labordynamicsinstitute/ssc-mirror",
        help="GitHub repo slug (owner/name) used to fetch tags via API",
    )
    parser.add_argument(
        "--token",
        default=os.environ.get("GITHUB_TOKEN", ""),
        help="GitHub API token (falls back to GITHUB_TOKEN env var)",
    )
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # --- Packages ---
    pkg_dir = Path(args.pkg_dir)
    if not pkg_dir.exists():
        print(f"ERROR: pkg-dir does not exist: {pkg_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"Scanning PKG files in {pkg_dir} …")
    packages = collect_packages(pkg_dir)
    print(f"  Found {len(packages)} packages.")

    packages_out = out_dir / "packages.json"
    with open(packages_out, "w", encoding="utf-8") as fh:
        json.dump(packages, fh, ensure_ascii=False, separators=(",", ":"))
    print(f"  Written → {packages_out}")

    # --- Tags ---
    print(f"Fetching tags for {args.repo} …")
    token = args.token or None
    tag_names = fetch_tags_via_api(args.repo, token=token)
    if not tag_names:
        print("  WARNING: No tags retrieved. Tags data will be empty.")

    print(f"  Found {len(tag_names)} date tags.")
    ranges = compute_ranges(tag_names)
    print(f"  Identified {len(ranges)} contiguous range(s).")

    tags_payload = {
        "tags": tag_names,
        "ranges": ranges,
    }
    tags_out = out_dir / "tags.json"
    with open(tags_out, "w", encoding="utf-8") as fh:
        json.dump(tags_payload, fh, ensure_ascii=False, separators=(",", ":"))
    print(f"  Written → {tags_out}")


if __name__ == "__main__":
    main()
