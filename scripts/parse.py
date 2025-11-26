import json
import time
import os
from tqdm import tqdm
import pdfplumber
from parse_utils import color_map, dump_qml,extract_character, merge_text_elements, extract_character, find_text, find_element_containing_point, find_text_element_containing_point, extract_text_elements, perform_text_extraction, SCALING_FACTOR

from dataclasses import dataclass, asdict, field

def parse_lighthouses(text_elements, page_number):
    global total_number_of_lighthouses
    DEBUG_FYRNR = "053210"
    DEBUG_PAGE = 97
    
    @dataclass
    class Lighthouse:
        fyrnr: str
        page_number: int
        bounding_box: list[tuple[int, int]]
        name: str | None = None
        latitude: str | None = None
        longitude: str | None = None
        character: dict | None = None
        pattern: str | None = None
        height: str | None = None
        maxRange: float | None = None
        sectors: list[dict] = field(default_factory=list)
        
    lighthouses_on_page = {}
    fyrnr_with_bounding_boxes = []
    
    if page_number == DEBUG_PAGE:
        print(f"\n=== DEBUG: Processing page {page_number} ===")
        print(f"Total text elements on page: {len(text_elements)}")
    
    # Find Fyrnr. elements. y coordinates start at 180 and increase by 10 for each line 
    for y in range(int(180/SCALING_FACTOR), int(1550/SCALING_FACTOR), int(10/SCALING_FACTOR)):
        FYRNR_X_COORDINATE = 153/SCALING_FACTOR
        element = find_element_containing_point(FYRNR_X_COORDINATE, y, text_elements)
        if element:
            fyrnr = element['description']
            if not fyrnr in lighthouses_on_page:
                lighthouses_on_page[fyrnr] = True # Found it
                fyrnr_with_bounding_boxes.append({
                    'fyrnr': fyrnr,
                    'bounding_box': element['bounding_box']
                })
    # Compute the full bounding box for each lighthouse
    for index, fyrnr_with_bounding_box in enumerate(fyrnr_with_bounding_boxes):
        DELTA_Y_FROM_TOP_OF_NEXT_BOX_TO_BOTTOM_OF_THIS_LIGHTHOUSE = 11/SCALING_FACTOR
        Y_FOR_LAST_LIGHTHOUSE = 1590/SCALING_FACTOR
        X_MAX_FOR_LIGHTHOUSE_BOUNDING_BOX = 2250/SCALING_FACTOR
        if index < len(fyrnr_with_bounding_boxes) - 1:
            next_fyrnr_with_bounding_box = fyrnr_with_bounding_boxes[index + 1]
            fyrnr = fyrnr_with_bounding_box['fyrnr']
            bounding_box = fyrnr_with_bounding_box['bounding_box']
            next_bounding_box = next_fyrnr_with_bounding_box['bounding_box']
            full_bounding_box = [bounding_box[0], (X_MAX_FOR_LIGHTHOUSE_BOUNDING_BOX, next_bounding_box[0][1] - DELTA_Y_FROM_TOP_OF_NEXT_BOX_TO_BOTTOM_OF_THIS_LIGHTHOUSE)]
        else:
            # This is the last lighthouse
            fyrnr = fyrnr_with_bounding_box['fyrnr']
            bounding_box = fyrnr_with_bounding_box['bounding_box']
            full_bounding_box = [bounding_box[0], (X_MAX_FOR_LIGHTHOUSE_BOUNDING_BOX, Y_FOR_LAST_LIGHTHOUSE)]
        
        lighthouses_on_page[fyrnr] = Lighthouse(fyrnr, page_number, full_bounding_box)
        if page_number == DEBUG_PAGE and fyrnr == DEBUG_FYRNR:
            print(f"\n=== DEBUG: Found lighthouse {fyrnr} ===")
            print(f"Bounding box: {full_bounding_box}")
    
    for fyrnr, lighthouse in lighthouses_on_page.items():
        total_number_of_lighthouses += 1
        is_debug_lighthouse = (page_number == DEBUG_PAGE and fyrnr == DEBUG_FYRNR)
        
        NAME_X_COORDINATE = 220/SCALING_FACTOR
        NAME_Y_COORDINATE = lighthouse.bounding_box[0][1] + 36/SCALING_FACTOR
        name = find_text_element_containing_point(NAME_X_COORDINATE, NAME_Y_COORDINATE, text_elements)
        lighthouses_on_page[fyrnr].name = name
        
        LATITUDE_X_COORDINATE = 650/SCALING_FACTOR
        LATITUDE_Y_COORDINATE = lighthouse.bounding_box[0][1] + 7/SCALING_FACTOR
        
        latitude = find_text_element_containing_point(LATITUDE_X_COORDINATE, LATITUDE_Y_COORDINATE, text_elements)
        # Convert to degrees
        latitude = float(latitude.split()[0]) + float(latitude.split()[1]) / 60
        
        LONGITUDE_X_COORDINATE = 650/SCALING_FACTOR
        LONGITUDE_Y_COORDINATE = lighthouse.bounding_box[0][1] + 32/SCALING_FACTOR
        
        longitude = find_text_element_containing_point(LONGITUDE_X_COORDINATE, LONGITUDE_Y_COORDINATE, text_elements)
        # Convert to degrees
        longitude = float(longitude.split()[0]) + float(longitude.split()[1]) / 60

        lighthouses_on_page[fyrnr].latitude = latitude
        lighthouses_on_page[fyrnr].longitude = longitude

        PATTERN_X_COORDINATE = 800/SCALING_FACTOR
        PATTERN_Y_COORDINATE = lighthouse.bounding_box[0][1] + 7/SCALING_FACTOR
        pattern = find_text_element_containing_point(PATTERN_X_COORDINATE, PATTERN_Y_COORDINATE, text_elements)
        lighthouses_on_page[fyrnr].pattern = pattern
        character = extract_character(pattern)
        lighthouses_on_page[fyrnr].character = character

        HEIGHT_OVER_SEA_LEVEL_X_COORDINATE = 940/SCALING_FACTOR
        HEIGHT_OVER_SEA_LEVEL_Y_COORDINATE = lighthouse.bounding_box[0][1] + 7/SCALING_FACTOR
        height_over_sea_level = find_text_element_containing_point(HEIGHT_OVER_SEA_LEVEL_X_COORDINATE, HEIGHT_OVER_SEA_LEVEL_Y_COORDINATE, text_elements)    
        lighthouses_on_page[fyrnr].height = float(height_over_sea_level.replace(",", ".")) if height_over_sea_level else None

        LYSVIDDE_X_COORDINATE = 1338/SCALING_FACTOR
        LYSVIDDE_R_Y_COORDINATE = lighthouse.bounding_box[0][1] + 7/SCALING_FACTOR
        LYSVIDDE_G_Y_COORDINATE = lighthouse.bounding_box[0][1] + 32/SCALING_FACTOR
        LYSVIDDE_W_Y_COORDINATE = lighthouse.bounding_box[0][1] + 57/SCALING_FACTOR
        lysvidde_r = find_text_element_containing_point(LYSVIDDE_X_COORDINATE, LYSVIDDE_R_Y_COORDINATE, text_elements)
        lysvidde_g = find_text_element_containing_point(LYSVIDDE_X_COORDINATE, LYSVIDDE_G_Y_COORDINATE, text_elements)
        lysvidde_w = find_text_element_containing_point(LYSVIDDE_X_COORDINATE, LYSVIDDE_W_Y_COORDINATE, text_elements)
        
        lysvidde_r = float(lysvidde_r.replace(",", ".")) if lysvidde_r else None
        lysvidde_g = float(lysvidde_g.replace(",", ".")) if lysvidde_g else None
        lysvidde_w = float(lysvidde_w.replace(",", ".")) if lysvidde_w else None
        ranges = [r for r in [lysvidde_r, lysvidde_g, lysvidde_w] if r is not None]
        if ranges:
            lighthouses_on_page[fyrnr].maxRange = max(ranges)
            # Convert to meters
            lighthouses_on_page[fyrnr].maxRange = lighthouses_on_page[fyrnr].maxRange * 1852
        
        if is_debug_lighthouse:
            print(f"\n=== DEBUG: Basic fields for {fyrnr} ===")
            print(f"Name: {name}")
            print(f"Latitude: {latitude}")
            print(f"Longitude: {longitude}")
            print(f"Pattern: {pattern}")
            print(f"Height: {lighthouses_on_page[fyrnr].height}")
            print(f"Lysvidde R: {lysvidde_r}, G: {lysvidde_g}, W: {lysvidde_w}")
            print(f"MaxRange: {lighthouses_on_page[fyrnr].maxRange}")
        # Find sectors
        SECTOR_NUMBER_X_COORDINATE = 1440/SCALING_FACTOR
        SECTOR_COLOR_X_COORDINATE = 1482/SCALING_FACTOR
        SECTOR_FIRST_COLOR_Y_COORDINATE = lighthouse.bounding_box[0][1] + 9/SCALING_FACTOR
        SECTOR_COLOR_LINE_HEIGHT = 5/SCALING_FACTOR
        current_y_coordinate = SECTOR_FIRST_COLOR_Y_COORDINATE

        SINGLE_LINE_HEIGHT = 28/SCALING_FACTOR
        SECTOR_FIRST_ANGLE_X_COORDINATE = 1536/SCALING_FACTOR
        SECTOR_SECOND_ANGLE_X_COORDINATE = 1614/SCALING_FACTOR
        
        # Track processed sectors by (color, from_angle, to_angle) to avoid duplicates
        # from multi-line descriptions and to catch consecutive same-color sectors
        processed_sectors = set()
        
        if is_debug_lighthouse:
            print(f"\n=== DEBUG: Starting sector parsing loop for {fyrnr} ===")
            print(f"Bounding box bottom Y: {lighthouse.bounding_box[1][1]}")
            print(f"Starting Y coordinate: {current_y_coordinate}")
            print(f"Sector color line height: {SECTOR_COLOR_LINE_HEIGHT}")
        
        loop_iteration = 0
        while current_y_coordinate < lighthouse.bounding_box[1][1]:
            loop_iteration += 1
            sector_color = find_element_containing_point(SECTOR_COLOR_X_COORDINATE, current_y_coordinate, text_elements)
            
            if is_debug_lighthouse:
                print(f"\n--- Loop iteration {loop_iteration} ---")
                print(f"Current Y coordinate: {current_y_coordinate}")
                print(f"Sector color found: {sector_color['description'] if sector_color else None}")
                if sector_color:
                    print(f"Sector color bounding box: {sector_color['bounding_box']}")
            
            # Process any valid color found (not just on color change)
            if sector_color and sector_color['description'] in ['R', 'G', 'W']:
                if is_debug_lighthouse:
                    print(f"Valid color {sector_color['description']} detected, checking if already processed...")
                
                # Get sector number
                sector_number = find_element_containing_point(SECTOR_NUMBER_X_COORDINATE, current_y_coordinate, text_elements)
                sector_number = sector_number.get('description') if sector_number else None
                if sector_number is not None:
                    sector_number = int(sector_number)
                
                # Calculate mean Y coordinate for angle lookup
                mean_y_coordinate = (sector_color['bounding_box'][0][1] + sector_color['bounding_box'][2][1]) / 2
                
                if is_debug_lighthouse:
                    print(f"Sector number: {sector_number}")
                    print(f"Mean Y coordinate: {mean_y_coordinate}")
                
                # Parse angles first to create unique key
                sector_from = find_text_element_containing_point(SECTOR_FIRST_ANGLE_X_COORDINATE, mean_y_coordinate, text_elements)
                sector_to = find_text_element_containing_point(SECTOR_SECOND_ANGLE_X_COORDINATE, mean_y_coordinate, text_elements)
                
                if is_debug_lighthouse:
                    print(f"Raw sector_from string: {sector_from}")
                    print(f"Raw sector_to string: {sector_to}")
                
                sector_from_float = float(sector_from.replace(",", ".")) if sector_from else None
                sector_to_float = float(sector_to.replace(",", ".").replace("-", "")) if sector_to else None
                
                if is_debug_lighthouse:
                    print(f"Parsed sector_from_float: {sector_from_float}")
                    print(f"Parsed sector_to_float: {sector_to_float}")
                
                if sector_from_float is None:
                    print(f"WARNING! Sector from is None for {fyrnr} {sector_color['description']} {sector_from}. Choosing 0.0 instead.")
                    sector_from_float = 0.0
                
                # Create unique key to detect duplicates (multi-line descriptions)
                sector_key = (sector_color['description'], sector_from_float, sector_to_float)
                
                if is_debug_lighthouse:
                    print(f"Sector key: {sector_key}")
                    print(f"Already processed: {sector_key in processed_sectors}")
                
                # Only process if we haven't seen this sector definition before
                if sector_key not in processed_sectors:
                    processed_sectors.add(sector_key)
                    
                    sector_data = {
                        'color': color_map[sector_color['description']],
                        'number': sector_number,
                        'start': sector_from_float,
                        'stop': float(sector_to.replace(",", ".").replace("-", ""))
                    }
                    
                    if is_debug_lighthouse:
                        print(f"Appending new sector: {sector_data}")
                    
                    lighthouses_on_page[fyrnr].sectors.append(sector_data)
                elif is_debug_lighthouse:
                    print(f"Sector already processed (likely multi-line description), skipping")
            elif is_debug_lighthouse:
                if not sector_color:
                    print("No sector color found at this Y coordinate")
                elif sector_color['description'] not in ['R', 'G', 'W']:
                    print(f"Sector color {sector_color['description']} is not R/G/W, skipping")
                
            current_y_coordinate += SECTOR_COLOR_LINE_HEIGHT
        
        if is_debug_lighthouse:
            print(f"\n=== DEBUG: Finished sector parsing loop for {fyrnr} ===")
            print(f"Total loop iterations: {loop_iteration}")
            print(f"Total sectors found: {len(lighthouses_on_page[fyrnr].sectors)}")
            print(f"Final sectors list: {lighthouses_on_page[fyrnr].sectors}")
    
    def should_keep_lighthouse(lighthouse):
        if lighthouse.maxRange is None:
            return False
        if lighthouse.height is None:
            return False
        if len(lighthouse.sectors) == 0:
            return False
        return True

    if page_number == DEBUG_PAGE and DEBUG_FYRNR in lighthouses_on_page:
        debug_lighthouse = lighthouses_on_page[DEBUG_FYRNR]
        print(f"\n=== DEBUG: Lighthouse {DEBUG_FYRNR} before filtering ===")
        print(f"maxRange: {debug_lighthouse.maxRange}")
        print(f"height: {debug_lighthouse.height}")
        print(f"number of sectors: {len(debug_lighthouse.sectors)}")
        print(f"Will be kept: {should_keep_lighthouse(debug_lighthouse)}")
    
    lighthouses_on_page = {
        fyrnr: lighthouse 
        for fyrnr, lighthouse in lighthouses_on_page.items() 
        if should_keep_lighthouse(lighthouse)
    }
    
    if page_number == DEBUG_PAGE:
        print(f"\n=== DEBUG: After filtering, {len(lighthouses_on_page)} lighthouses kept on page {page_number} ===")
        if DEBUG_FYRNR in lighthouses_on_page:
            print(f"Lighthouse {DEBUG_FYRNR} was kept")
        else:
            print(f"Lighthouse {DEBUG_FYRNR} was filtered out")
    
    return lighthouses_on_page.values()


pdf_path = "scripts/Fyrliste_HeleLandet.pdf"
if not os.path.exists(pdf_path):
    print("Downloading Fyrliste_HeleLandet.pdf from https://nfs.kystverket.no/fyrlister/Fyrliste_HeleLandet.pdf")
    # Download from https://nfs.kystverket.no/fyrlister/Fyrliste_HeleLandet.pdf
    import requests
    response = requests.get("https://nfs.kystverket.no/fyrlister/Fyrliste_HeleLandet.pdf")
    with open(pdf_path, "wb") as f:
        f.write(response.content)

total_number_of_lighthouses = 0
lighthouses = []
with pdfplumber.open(pdf_path) as pdf:  # type: ignore
    page_number = 0
    for pdf_page in tqdm(pdf.pages, desc="Processing pages"):
        page_number += 1
        # print(f"Processing page {i} of {len(pdf.pages)}")
        text_on_page = pdf_page.extract_text()
        search_text = ["Lysvidde", "Fyrnr.", "Kartnr."]
        should_parse_page = all(map(lambda needle: needle in text_on_page, search_text))
        if not should_parse_page:
            continue
        text_elements = perform_text_extraction(pdf_page)
        lighthouses_on_page = parse_lighthouses(text_elements, page_number)
        lighthouses.extend(lighthouses_on_page)

lighthouses_as_dicts = [asdict(lighthouse) for lighthouse in lighthouses]
for lighthouse in lighthouses_as_dicts:
    del lighthouse['bounding_box']
    
with open("scripts/lighthouses.json", "w") as f:
    print("Wrote the file")
    json.dump(lighthouses_as_dicts, f, indent=2, ensure_ascii=False)
qml_string = dump_qml(lighthouses_as_dicts)
with open("LighthouseList.qml", "w") as f:
    f.write(qml_string)
print("total_number_of_lighthouses: ", total_number_of_lighthouses)
print("total_real_number_of_lighthouses: ", len(lighthouses))
