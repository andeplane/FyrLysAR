import re
from pdfplumber.utils.text import WordExtractor, objects_to_bbox

SCALING_FACTOR = 2.77793494

def merge_text_elements(text_elements, max_x_distance=10/SCALING_FACTOR, max_y_distance=5/SCALING_FACTOR):
    """
    Merges text elements that are horizontally close and vertically aligned based on bounding box sides.

    Args:
        text_elements (list): List of text elements with 'description' and 'bounding_box'.
        max_x_distance (int): Maximum horizontal distance in pixels to consider for merging.
        max_y_distance (int): Maximum vertical distance in pixels to consider for merging.

    Returns:
        list: A new list of merged text elements.
    """
    if not text_elements:
        return []

    # Sort text elements by top-left y-coordinate, then by left x-coordinate
    sorted_elements = sorted(text_elements, key=lambda el: (el['bounding_box'][0][1], el['bounding_box'][0][0]))
    elements_to_keep = []
    while True:
        merged = False
        merged_elements = []
        current_element = sorted_elements[0].copy()
        
        for next_element in sorted_elements[1:]:
            #print("Considering merging ", current_element['description'], " and ", next_element['description'])
            #print("  y coordinates: ", [coord[1] for coord in current_element['bounding_box']], " and ", [coord[1] for coord in next_element['bounding_box']])
            # Extract bounding box coordinates
            current_bbox = current_element['bounding_box']
            next_bbox = next_element['bounding_box']

            # Determine right side of current and left side of next
            current_right_x = max([coord[0] for coord in current_bbox])
            current_left_x = min([coord[0] for coord in current_bbox])
            next_left_x = min([coord[0] for coord in next_bbox])
            next_right_x = max([coord[0] for coord in next_bbox])

            # Calculate horizontal distance between right of current and left of next
            horizontal_distance1 = next_left_x - current_right_x
            horizontal_distance2 = current_left_x - next_right_x

            # Extract top y-coordinates for vertical alignment
            current_top_y = current_bbox[0][1]
            next_top_y = next_bbox[0][1]
            vertical_distance = abs(next_top_y - current_top_y)
            # Decide whether to merge
            if (abs(horizontal_distance1) < max_x_distance or abs(horizontal_distance2) < max_x_distance) and abs(vertical_distance) <= max_y_distance:
                # Merge descriptions
                # Decide which is left and which is right
                if current_right_x < next_left_x:
                    current_element['description'] += ' ' +  next_element['description']
                else:
                    current_element['description'] = next_element['description'] + ' ' + current_element['description']
                # Merge bounding boxes
                # New left_x is min of current and next
                new_left_x = min([coord[0] for coord in current_bbox] + [coord[0] for coord in next_bbox])
                # New right_x is max of current and next
                new_right_x = max([coord[0] for coord in current_bbox] + [coord[0] for coord in next_bbox])
                # New top_y is min of current and next
                new_top_y = min([coord[1] for coord in current_bbox] + [coord[1] for coord in next_bbox])
                # New bottom_y is max of current and next
                new_bottom_y = max([coord[1] for coord in current_bbox] + [coord[1] for coord in next_bbox])

                # Define new bounding box
                new_bounding_box = [
                    (new_left_x, new_top_y),
                    (new_right_x, new_top_y),
                    (new_right_x, new_bottom_y),
                    (new_left_x, new_bottom_y)
                ]
                current_element['bounding_box'] = new_bounding_box
                merged = True
            else:
                # No merge; add the current element to the list
                merged_elements.append(next_element)

        # Update sorted_elements for next iteration
        sorted_elements = merged_elements.copy()
        elements_to_keep.append(current_element)
        
        if len(sorted_elements) == 0:
            # Finished with all elements
            break
        else:
            current_element = merged_elements[0]
                
    return elements_to_keep


def extract_character(pattern):
    # Extract the light character
    # This method is intended to get input from extract_pattern above
    possible_classes = 'Iso|Fast|Oc|None|Fl|Q|VQ|FFl|LFl'

    if pattern is None:
        # TODO: Figure out how to display lighthouses without known pattern.
        return {
            "light_class": "None",
            "numflash": 0, 
            "extra_class": None, 
            "period": 0
        }
    
    light_classes = re.findall(possible_classes, pattern)
    
    if len(light_classes) > 2:
        # Don't think any lighthouse has more than two lightclasses
        print(f"{len(light_class)} light classes found", light_class)     
    
    light_class = light_classes[0]
    # TODO: Figure out what to do about the South Cardinal
    if len(light_classes) == 2:
        # some have more than one, like the South Cardinal: (Q or VQ) + LFl
        extra_class = light_classes[1]
    else:
        extra_class = None
        
    # Extract number of flashes
    flash_string = re.findall('[(][\d+][)]', pattern)
    if len(flash_string) == 0:
        numflash = 1
    elif len(flash_string) == 1:
        numflash = int(flash_string[0][1:-1])
    else:
        print(f"{len(flash_string)} is  a strange number of flashes for lighthouse. {flash_string}")

    # Extract the period
    period = re.findall(' [\d]{0,2}s', pattern)
    if len(period) == 0:
        # Period not explicitly stated.
        if light_class == "Q":
            period = 1.0
        elif light_class == "VQ":
            period = 0.5
        elif light_class == "UQ":
            # Haven't seen ultra quick in the Norwegian Fyrliste yet.
            period = 0.25
        elif light_class == "Fast":
            period = 1.0
        else:
            print(f"Error: Light class {light_class} from pattern {pattern} should have an explicit period.")
    else:
        period = float(period[0][:-1])
    # TODO: Figure out what to do about "Fast lys yellow"
    # The pattern "Fast lys yellow" indicates that there is one single sector
    # and that this sector is yellow and 360 deg wide. Fyrliste seems to not
    # specify sectors for "Fast lys yellow". I guess:
    return {
        "light_class": light_class, 
        "numflash": numflash, 
        "extra_class": extra_class, 
        "period": period
    }


def find_text(target_text, text_elements):
    """
    Finds the first occurrence of the target text in the list of text elements.

    Args:
        target_text (str): The text to search for.
        text_elements (list): List of text elements with 'description' and 'bounding_box'.

    Returns:
        dict or None: The text element containing the target text or None if not found.
    """
    target_lower = target_text.strip().lower().replace(',', '').replace(' ', '').replace('.', '')
    for element in text_elements:
        if element['description'].strip().lower().replace(',', '').replace(' ', '').replace('.', '') == target_lower:
            return element
    return None

def find_element_containing_point(x, y, text_elements):
    """
    Finds all text elements whose bounding boxes contain the given (x, y) point.

    Args:
        x (int): The x-coordinate of the point.
        y (int): The y-coordinate of the point.
        text_elements (list): List of text elements with 'description' and 'bounding_box'.

    Returns:
        list: A list of text elements containing the point.
    """
    containing_elements = []
    for element in text_elements:
        bbox = element['bounding_box']
        # Extract x and y coordinates separately
        x_coords = [coord[0] for coord in bbox]
        y_coords = [coord[1] for coord in bbox]
        min_x, max_x = min(x_coords), max(x_coords)
        min_y, max_y = min(y_coords), max(y_coords)

        if min_x <= x <= max_x and min_y <= y <= max_y:
            containing_elements.append(element)
    if len(containing_elements) > 1:
        print(f"WARNING! Found {len(containing_elements)} elements containing point {x}, {y}")
    return containing_elements[0] if len(containing_elements) > 0 else None

def find_text_element_containing_point(x, y, text_elements):
    element = find_element_containing_point(x, y, text_elements)
    return element['description'] if element else None

def extract_text_elements(pdf_page):
    elements = []

    lines = pdf_page.extract_text_lines(layout=True, x_density=3)
    for idx, line in enumerate(lines):
        word_pointer = 0  # noqa: N806
        chars = line["chars"]
        annotations = []
        for word in line["text"].split():
            # print("  word", word)
            ordered_chars = chars[word_pointer : word_pointer + len(word)]
            word_pointer += len(word)  # noqa: N806

            x0, y0, x1, y1 = objects_to_bbox(ordered_chars)
            elements.append({
                'description': word,
                'bounding_box': [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
            })
    return elements
    
def perform_text_extraction(pdf_page):
    texts_with_bounding_box = extract_text_elements(pdf_page)
    
    # Merge text elements based on proximity
    merged_texts = merge_text_elements(texts_with_bounding_box, max_x_distance=10/SCALING_FACTOR, max_y_distance=5/SCALING_FACTOR)
    return merged_texts
