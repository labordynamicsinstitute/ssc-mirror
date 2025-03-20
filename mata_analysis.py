#!/usr/bin/env python3
import os
import csv
import re
import argparse
import sys
from collections import Counter

# Parse command line arguments
parser = argparse.ArgumentParser(description='Search for Mata usage in Stata files')
parser.add_argument('--dir', default='fmwww.bc.edu/repec', help='Directory to search (default: fmwww.bc.edu/repec)')
parser.add_argument('--output', default='mata_stats.csv', help='Output CSV file name (default: mata_stats.csv)')
args = parser.parse_args()

# Directory to search - use relative path from where script is run
base_dir = args.dir
output_file = args.output

# Ensure output file has correct path
script_dir = os.path.dirname(os.path.abspath(__file__))
if not os.path.isabs(output_file):
    output_file = os.path.join(script_dir, output_file)

# Function to count occurrences of patterns in a file
def count_patterns(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().lower()
            
            # Count occurrences of patterns
            mata_count = content.count('mata:')
            void_count = content.count('void')
            
            return mata_count, void_count
    except Exception as e:
        print(f"Error reading file {file_path}: {e}", file=sys.stderr)
        return 0, 0

# Stats counters
total_files = 0
files_with_mata = 0
files_with_void = 0
results = []

print(f"Searching for .do and .ado files in {base_dir}...")

# Walk through the directory
for root, dirs, files in os.walk(base_dir):
    # Skip .git directory
    if '.git' in root:
        continue
        
    for file in files:
        # Only process .do and .ado files
        if file.endswith('.do') or file.endswith('.ado'):
            file_path = os.path.join(root, file)
            total_files += 1
            
            # Print progress every 100 files
            if total_files % 100 == 0:
                print(f"Progress: Processed {total_files} files...")
            
            # Count patterns
            mata_count, void_count = count_patterns(file_path)
            
            # Update stats
            if mata_count > 0:
                files_with_mata += 1
            if void_count > 0:
                files_with_void += 1
            
            # Store result
            results.append({
                'file_path': file_path,
                'mata_count': mata_count,
                'void_count': void_count
            })

# Write results to CSV
with open(output_file, 'w', newline='') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow(['File Path', 'mata: Count', 'void Count'])
    
    for result in results:
        csv_writer.writerow([
            result['file_path'],
            result['mata_count'],
            result['void_count']
        ])

# Write summary statistics
with open(os.path.join(os.path.dirname(output_file), 'mata_summary.csv'), 'w', newline='') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow(['Statistic', 'Count'])
    csv_writer.writerow(['Total Files Searched', total_files])
    csv_writer.writerow(['Files with mata:', files_with_mata])
    csv_writer.writerow(['Files with void', files_with_void])
    
    # Calculate percentages if there are files
    if total_files > 0:
        csv_writer.writerow(['Percentage with mata:', f"{(files_with_mata / total_files) * 100:.2f}%"])
        csv_writer.writerow(['Percentage with void', f"{(files_with_void / total_files) * 100:.2f}%"])

print(f"Analysis complete. Processed {total_files} .do/.ado files.")
print(f"Results saved to {output_file} and {os.path.join(os.path.dirname(output_file), 'mata_summary.csv')}")