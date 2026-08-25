#!/usr/bin/env python3
import re
import subprocess
from pathlib import Path
import csv

VERSION_RE = re.compile(
    r"""^\s*                        # start of line, optional whitespace
        (?:\*!|\*{3})               # anchor: *!  or  ***
        \s*
        (?:[A-Za-z_][\w-]*\s+)?     # optional word (e.g. 'version', 'Version', or a package name)
        v?                          # optional v prefix
        (\d+(?:\.\d+){1,3})         # capture: 1.2 / 1.2.3 / 1.2.3.4  (at least one dot, won't ID "*!version 9" or )
    """,
    re.IGNORECASE | re.VERBOSE | re.MULTILINE,
)

DIST_DATE_RE = re.compile(r"^d\s+Distribution-Date:\s*(\d{8})", re.MULTILINE)

PKG_PATH_RE = re.compile(r"^(fmwww\.bc\.edu/repec/bocode/([a-z0-9_]))/([^/]+)\.pkg$")

ADO_PATH_RE = re.compile(r"^(fmwww\.bc\.edu/repec/bocode/([a-z0-9_]))/([^/]+)\.ado$")


def file_at_commit(repo, commit, path):
    #Return file content at a given commit, or None if it doesn't exist at that point
    try:
        raw = subprocess.run(
            ["git", "-C", str(repo), "show", f"{commit}:{path}"],
            capture_output=True, check=True,).stdout
    except subprocess.CalledProcessError:
        return None # still want to know if it doesn't exist
    return raw.decode("utf-8", errors="replace")



def extract_version(repo, commit, pkg_dir, pkg_name):
    ado_text = file_at_commit(repo, commit, f"{pkg_dir}/{pkg_name}.ado")
    if ado_text != None:
        ver = VERSION_RE.search(ado_text)
        if ver != None:
            return ver.group(1) 

    pkg_text = file_at_commit(repo, commit, f"{pkg_dir}/{pkg_name}.pkg")
    if pkg_text != None:
        m = DIST_DATE_RE.search(pkg_text)
        if m != None:
            return m.group(1)
    return None

def list_commits(repo):
    # List of all commits, oldest first as (SHA, date) 
    out = subprocess.run(
        ["git", "-C", str(repo), "log", "--format=%H %cI", "--reverse"],
        capture_output=True, text=True, check=True,
    ).stdout # Date the mirror saw it, NOT date the authors wrote it!
    commits = []
    for line in out.splitlines():
        sha, date = line.split(" ", 1)
        commits.append((sha, date))
    return commits

def full_snapshot(repo, commit):
    #List every package present at specific commit as (pkg_dir, pkg_name) tuples.
    out = subprocess.run(
        ["git", "-C", str(repo), "ls-tree", "-r", "--name-only", commit],
        capture_output=True, text=True, check=True,
    ).stdout
    packages = []
    for path in out.splitlines():
        m = PKG_PATH_RE.match(path)
        if m != None:
            pkg_dir, letter, name = m.groups()
            packages.append((pkg_dir, name))
    return packages


def changed_packages(repo, parent, commit):
    #Packages whose .pkg or .ado files changed between parent and commit.

    out = subprocess.run(
        ["git", "-C", str(repo), "diff-tree", "-r", "--no-commit-id",
         "--name-only", parent, commit],
        capture_output=True, text=True, check=True,
    ).stdout

    changed = {}
    for path in out.splitlines():
        m = PKG_PATH_RE.match(path)
        if m != None:
            pkg_dir, letter, name = m.groups()
            changed[(pkg_dir, name)] = None
            continue
        m = ADO_PATH_RE.match(path)
        if m != None:
            pkg_dir, letter, name = m.groups()
            changed[(pkg_dir, name)] = None
    return changed



def main():
    repo = "releases-bare"
    commits = list_commits(repo)
    print(f"{len(commits)} commits: {commits[0][1]} .. {commits[-1][1]}")

    base_sha, base_date = commits[0]
    print("Baseline snapshot...")

    state = {}   # (pkg_dir, pkg_name) -> last known version string (or None)
    rows = []    # (package, version, version_date, proxied)

    for i, (pkg_dir, pkg_name) in enumerate(full_snapshot(repo, base_sha)):
        version = extract_version(repo, base_sha, pkg_dir, pkg_name)
        state[(pkg_dir, pkg_name)] = version
        rows.append((pkg_name, version or "", base_date, ""))
        if (i + 1) % 500 == 0:
            print(f"  {i + 1} packages...")

    print(f"Baseline done: {len(rows)} packages")

    for i in range(1, len(commits)):
        parent_sha, _ = commits[i - 1]
        commit_sha, commit_date = commits[i]

        for key in changed_packages(repo, parent_sha, commit_sha):
            pkg_dir, pkg_name = key
            new_version = extract_version(repo, commit_sha, pkg_dir, pkg_name)
            old_version = state.get(key, "NEVER_SEEN")

            if key not in state:
                # new package appearing mid-window (or phantom helper-.ado stem)
                # only record if it's a real package (has a .pkg at this commit)
                if file_at_commit(repo, commit_sha, f"{pkg_dir}/{pkg_name}.pkg") is None:
                    continue          # phantom: helper .ado with no .pkg — skip for v1
                rows.append((pkg_name, new_version or "", commit_date, ""))
            elif new_version != old_version:
                # reported version changed: a real, self-reported update
                rows.append((pkg_name, new_version or "", commit_date, ""))
            else:
                # content changed but reported version did NOT: the whole point
                rows.append((pkg_name, new_version or "", commit_date, "diff"))

            state[key] = new_version

        if i % 20 == 0 or i == len(commits) - 1:
            print(f"  commit {i + 1}/{len(commits)} ({commit_date})")

    # in a REPL after, or add temporarily to main():
    none_count = sum(1 for v in state.values() if v is None)
    print(f"{none_count} packages with no extractable version")

    datever = sum(1 for v in state.values() if v and len(v) == 8 and v.isdigit())
    print(f"{datever} using Distribution-Date fallback")

    dotted = sum(1 for v in state.values() if v and "." in v)
    print(f"{dotted} with real dotted versions")

    
    with open("version_table.csv", "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["package", "version", "version_date", "proxied"])
        w.writerows(rows)
    print(f"Wrote {len(rows)} rows to version_table.csv")

    return state, rows


main()







## Testing:

#Testing file_at_commit
#text = file_at_commit("releases-bare", "HEAD", "fmwww.bc.edu/repec/bocode/a/a2reg.pkg")
#print(text[:300])
#print(file_at_commit("releases-bare", "HEAD", "fmwww.bc.edu/repec/bocode/z/doesnotexist.ado"))



#Testing extract_version
#No header, goes to distribution date
#print(extract_version("releases-bare", "HEAD", "fmwww.bc.edu/repec/bocode/a", "a2reg"))
#ouput: 20080611

#package with version in ado file that matches regex
#print(extract_version("releases-bare", "HEAD", "fmwww.bc.edu/repec/bocode/o", "outreg2"))
#output: 2.3.2

#no package
#print(extract_version("releases-bare", "HEAD", "fmwww.bc.edu/repec/bocode/z", "nonexistent"))
#output: None

#Testing list_commits
#commits = list_commits("releases-bare")
#print(len(commits))          # expect 100
#print(commits[0])            # oldest — around end of March 2026
#print(commits[-1])           # newest — early July 2026


#Testing full_snapshot
#commits = list_commits("releases-bare")
#pkgs = full_snapshot("releases-bare", commits[0][0])
#print(len(pkgs))       # expect roughly 3,800-4,000
#print(pkgs[:3])        # e.g. [('fmwww.bc.edu/repec/bocode/_', '_gapport'), ...]


# Testing changed_packages
#ch = changed_packages("releases-bare",
#                      "a3d30edc63a9138d3e089a94af659bc093192436",
#                      "ad01548f0708f74dc49cc7918870ce1543619dd2")
#for k in ch: print(k)