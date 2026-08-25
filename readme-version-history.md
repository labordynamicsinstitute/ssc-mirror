
What this does
The SSC archive (the main source of user-written Stata packages) doesn't keep a public history of package versions; when a package is updated, the old version simply disappears. This repository's mirror takes daily snapshots of the entire archive, which means its git history quietly contains the full record of every package change over time.
build_version_table.py walks through that history and turns it into a simple table: for every package, every version ever observed, and the date it first appeared in the mirror. Where a package author reports a version number, we use it; where they only report a distribution date, we use that instead. Importantly, the script also catches "silent" updates — cases where a package's code changed but the author didn't update the version number (or doesn't report one at all). Those are flagged in a proxied column, so that every real change to a package is catalogued even when the package itself doesn't announce it.
The output is one CSV (version_table.csv) with four columns: package name, version, date first observed, and how the change was detected. This gives researchers a retrospective version history for SSC packages — useful for reproducibility work, where knowing exactly which version of a package a paper used can matter.

- Started with the following command:
```
git clone --bare --depth 100 --branch releases --single-branch \
  https://github.com/labordynamicsinstitute/ssc-mirror.git releases-bare
```

- Sometimes there is no version, other common cases:
```
*! Version X.X... date ...
*! version X.X... date ...
*! packagename X.X... date ...
*** Version X.XX... date ...
*! vX.X .. date ...
*! Version X.X...- date
```

- Need to be careful of `Version XX.X`, Not commented out. Referring to stata version!

- The .pkg files seem to always have `Distribution-Date: XXXXXXXX`

- Use the following command to see the changed files in two adjacent commits:
```
git -C releases-bare diff-tree -r --no-commit-id --name-only <oldSHA> <newSHA> | head -20
```




- Usually (but not always) both .pkg and .ado change at the same time.


- Structure of `build_version_table.py`:

```
file_at_commit(repo, SHA, filepath) returns files content at that commit

extract_version(repo, commit, pkg_dir, pkg_name) returns version string from .ado header (if possible), otherwise uses Distribution Date

list_commits(repo) returns [(SHA1, date1),....]

full_snapshot(repo, commit) returns a list  with every package present at specific commit

changed_packages(SHA1, SHA2) returns the changed .pkg/.ado files between two commits

main()
```

- When running on test data, the following was gotten:
```
97 packages with no extractable version
1486 using Distribution-Date fallback
2422 with real dotted versions
```
- Run script with `python build_version_table.py` from directory that holds `releases-bare` and script itself.