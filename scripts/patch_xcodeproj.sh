#!/bin/bash
#
# Patches the Qt-generated Xcode project for iOS App Store submission
# Wrapper script that calls the Python implementation for safe .pbxproj manipulation
#
# Usage: ./patch_xcodeproj.sh <path_to_xcodeproj> <version>
#
# This script:
# 1. Sets supported destinations to iPhone only (removes iPad, Mac Catalyst)
# 2. Sets the App Icon to use AppIcon asset catalog
# 3. Updates version numbers
#

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <path_to_xcodeproj> <version>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/patch_xcodeproj.py"

if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: Python patch script not found at $PYTHON_SCRIPT"
    exit 1
fi

# Call the Python script
python3 "$PYTHON_SCRIPT" "$@"
