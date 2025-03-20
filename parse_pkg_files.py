#!/usr/bin/env python3
import os
import re
import glob
import csv

# Get all pkg files
pkg_files = glob.glob('fmwww.bc.edu/repec/**/*.pkg', recursive=True)

# Output file
output_file = 'pkg_file_associations.csv'

# CSV header
header = ['path_filename', 'base_filename', 'package']

# Regular expression to match lines that start with "f "
file_pattern = re.compile(r'^f\s+(.*?)$')

# List to store results
results = []

# Process each pkg file
for pkg_file in pkg_files:
    # Extract package name (strip .pkg)
    package_name = os.path.basename(pkg_file).replace('.pkg', '')
    
    try:
        with open(pkg_file, 'r', encoding='utf-8', errors='replace') as f:
            for line in f:
                line = line.strip()
                match = file_pattern.match(line)
                if match:
                    # Get the full path filename from the file line
                    path_filename = match.group(1).strip()
                    # Extract base filename without the path
                    base_filename = os.path.basename(path_filename)
                    # Add to results
                    results.append([path_filename, base_filename, package_name])
    except Exception as e:
        print(f"Error processing {pkg_file}: {e}")

# Write results to CSV
with open(output_file, 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(header)
    writer.writerows(results)

print(f"CSV file created: {output_file}")
print(f"Total associations found: {len(results)}")