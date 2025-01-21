import json
import csv
from collections import Counter
from datetime import datetime

with open('scripts/lighthouses.json', 'r') as f:
    lighthouses = json.load(f)

lighthouses_with_problems = {}
lighthouses_by_fyrnr = {}
error_types = Counter()

def add_problem(lighthouse, problem):
    if lighthouse['fyrnr'] not in lighthouses_with_problems:
        lighthouses_with_problems[lighthouse['fyrnr']] = []
    lighthouses_with_problems[lighthouse['fyrnr']].append(problem)
    
    # Categorize error type
    if "No sector number for sector" in problem:
        error_types["Missing sector number"] += 1
    elif "Invalid sector number 0" in problem:
        error_types["Invalid sector number 0"] += 1
    elif "Gap in sector numbering" in problem:
        error_types["Gap in sector numbering"] += 1
    elif "Non sequential sector has a non-continuous angle" in problem:
        error_types["Non sequential sector has a non-continuous angle"] += 1

def check_sectors(lighthouse):
    sectors_with_numbers = []
    
    # Check for missing numbers while building list for sequence check
    for sector in lighthouse['sectors']:
        if sector['number'] is None:
            add_problem(lighthouse, f"No sector number for sector {sector['color']} ({sector['start']} - {sector['stop']})")
        elif sector['number'] == 0:
            add_problem(lighthouse, f"Invalid sector number 0 for sector {sector['color']} ({sector['start']} - {sector['stop']})")
        else:
            sectors_with_numbers.append(sector)
            
    # Skip sequence check if no numbered sectors
    if not sectors_with_numbers:
        return
    
    # Check for gaps in sequence
    expected_numbers = set(range(1, len(sectors_with_numbers) + 1))
    actual_numbers = set(sector['number'] for sector in sectors_with_numbers)
    missing_numbers = expected_numbers - actual_numbers
    
    for missing in missing_numbers:
        add_problem(lighthouse, f"Gap in sector numbering. Missing sector number {missing}")

    # iterate over all sectors and their next sector
    for sector_index, sector in enumerate(lighthouse['sectors'][:-1]):  # Exclude last sector
        next_sector = lighthouse['sectors'][sector_index + 1]
        # Check if the sector numbers are in sequence
        if sector['number'] is not None and next_sector['number'] is not None:
            if sector['number'] + 1 != next_sector['number']:
                # Now check the end angle vs next start angle
                if sector['stop'] != next_sector['start']:
                    add_problem(lighthouse, f"Non sequential sector has a non-continuous angle. {sector['stop']} != {next_sector['start']}")
        

for lighthouse in lighthouses:
    lighthouses_by_fyrnr[lighthouse['fyrnr']] = lighthouse
    check_sectors(lighthouse)

# Write to csv file
with open('scripts/lighthouses_with_problems.csv', 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['fyrnr', 'page_number', 'problem'])
    for lighthouse in lighthouses_with_problems:
        for problem in lighthouses_with_problems[lighthouse]:
            writer.writerow([lighthouse, lighthouses_by_fyrnr[lighthouse]['page_number'], problem])

# Generate markdown report
pages = set(lighthouse['page_number'] for lighthouse in lighthouses)
total_sectors = sum(len(lighthouse['sectors']) for lighthouse in lighthouses)
current_date = datetime.now().strftime('%Y-%m-%d')

report = f"""This PR updates the generated files based on the latest run.
Generated on: {current_date}

# Data Quality Report

## Dataset Overview
- Total number of lighthouses: {len(lighthouses)}
- Number of pages covered: {len(pages)}
- Total number of sectors: {total_sectors}

## Data Quality Issues
- Number of lighthouses with problems: {len(lighthouses_with_problems)}
- Percentage of problematic lighthouses: {(len(lighthouses_with_problems)/len(lighthouses))*100:.1f}%

### Error Type Breakdown
"""

for error_type, count in error_types.items():
    report += f"- {error_type}: {count} occurrences\n"

print(report)
