from pathlib import Path
import pandas as pd
import subprocess
import csv



folder = Path("./stata-pkg-files")
rows = []

for i, pkg in enumerate(folder.rglob("*.pkg")):
    pkgname = pkg.stem
    keyword = ""
    filename = ""
    extension = ""
    release = ""

    #if i > 295:
        #print(f"Opening package {i} - {pkgname})")

    try:
        with pkg.open(encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if line.startswith("f ") and line.endswith((".ado", ".scheme")):
                    filename = line[2:]
                    extension = Path(filename).suffix.lstrip(".")
                    keyword = Path(filename).stem.removeprefix("scheme-")
                    row = {'keyword': keyword, 'package': pkgname, 'filename': filename, 'extension': extension, 'release': release}
                    rows.append(row) 
    except Exception as e:
        print(pkg)
        raise

print("Finished Parsing!")



with open("crosswalk.csv", "w", newline="") as csvfile:
    writer = csv.DictWriter(
        csvfile,
        fieldnames = ["keyword", "package", "filename", "extension", "release"]
    )

    writer.writeheader()
    writer.writerows(rows)


print("Done!")
