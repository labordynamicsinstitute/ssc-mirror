#!/usr/bin/env python3
import os
import csv
import re
import subprocess
import sys
import argparse
from collections import defaultdict

# Parse command line arguments
parser = argparse.ArgumentParser(description='Analyze binary files in a directory.')
parser.add_argument('--dir', default='fmwww.bc.edu/repec', help='Directory to search (default: fmwww.bc.edu/repec)')
args = parser.parse_args()

# Directory to search - use relative path from where script is run
base_dir = args.dir
script_dir = os.path.dirname(os.path.abspath(__file__))
output_dir = os.path.join(script_dir, os.path.dirname(base_dir))

# Function to check if a file is binary
def is_binary(file_path):
    try:
        # For older Python versions that don't support capture_output
        result = subprocess.Popen(['file', '-b', file_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, _ = result.communicate()
        output = output.decode('utf-8', errors='ignore').lower()
        
        # Check if file command identifies it as binary
        if any(x in output for x in ['executable', 'binary', 'data', 'compiled', 'octet-stream']):
            return True
        # Additional check for plugin files
        if file_path.endswith('.plugin') or file_path.endswith('.dll'):
            return True
        return False
    except Exception as e:
        print(f"Error checking file {file_path}: {e}", file=sys.stderr)
        return False

# Function to determine platform from filename
def determine_platform(filename):
    filename = filename.lower()
    
    # Extract platform from filename
    if 'win' in filename:
        return 'Windows'
    elif 'mac' in filename or 'osx' in filename:
        return 'macOS'
    elif 'linux' in filename or 'unix' in filename:
        return 'Linux'
    
    # For files without platform info in name
    if filename.endswith('.plugin') or filename.endswith('.dll'):
        return 'Unknown Platform'
    
    return None  # Not a binary file or platform not detectable

# Stats counters
total_files = 0
binary_files = 0
platform_stats = defaultdict(int)

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)
output_csv = os.path.join(output_dir, 'binary_stats.csv')
summary_csv = os.path.join(output_dir, 'summary_stats.csv')

# Open CSV file for writing
with open(output_csv, 'w', newline='') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow(['File Path', 'Is Binary', 'Platform'])
    
    # Walk through the directory
    for root, dirs, files in os.walk(base_dir):
        # Skip .git directory
        if '.git' in root:
            continue
            
        for file in files:
            file_path = os.path.join(root, file)
            total_files += 1
            
            # Print progress every 100 files
            if total_files % 100 == 0:
                print(f"Progress: Processed {total_files} files, found {binary_files} binary files so far...")
            
            # Check if binary
            binary = is_binary(file_path)
            if binary:
                binary_files += 1
                
                # Determine platform
                platform = determine_platform(file)
                if platform:
                    platform_stats[platform] += 1
                
                # Write to CSV
                csv_writer.writerow([file_path, 'Yes', platform])
            else:
                csv_writer.writerow([file_path, 'No', 'N/A'])

# Write summary statistics to a separate CSV
with open(summary_csv, 'w', newline='') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow(['Statistic', 'Count'])
    csv_writer.writerow(['Total Files', total_files])
    csv_writer.writerow(['Binary Files', binary_files])
    csv_writer.writerow(['Non-Binary Files', total_files - binary_files])
    csv_writer.writerow(['', ''])
    csv_writer.writerow(['Platform Distribution', ''])
    
    for platform, count in platform_stats.items():
        csv_writer.writerow([platform, count])

print(f"Analysis complete. Found {binary_files} binary files out of {total_files} total files.")
print(f"Results saved to {output_csv} and {summary_csv}")
