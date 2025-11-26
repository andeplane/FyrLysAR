#!/bin/bash
#
# Patches the Qt-generated Xcode project for iOS App Store submission
# Uses native macOS tools (no Ruby gems required)
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

XCODEPROJ_PATH="$1"
VERSION="$2"
PBXPROJ_PATH="$XCODEPROJ_PATH/project.pbxproj"

echo "Patching Xcode project: $XCODEPROJ_PATH"
echo "Version: $VERSION"

if [ ! -f "$PBXPROJ_PATH" ]; then
    echo "Error: project.pbxproj not found at $PBXPROJ_PATH"
    exit 1
fi

# Create a backup
cp "$PBXPROJ_PATH" "$PBXPROJ_PATH.backup"

echo "Patching project.pbxproj..."

# Function to add or update a build setting
patch_build_setting() {
    local key="$1"
    local value="$2"
    local file="$3"
    
    # Check if the setting already exists
    if grep -q "^[[:space:]]*$key = " "$file"; then
        # Update existing setting
        sed -i '' "s/^[[:space:]]*$key = .*/$key = $value;/g" "$file"
        echo "  Updated: $key = $value"
    else
        # Setting doesn't exist, we'll add it in buildSettings blocks
        # This is more complex, so we use a different approach
        echo "  Note: $key not found in project, may need manual addition"
    fi
}

# Use sed to patch the project.pbxproj file
# These patterns work with the Xcode project format

# 1. Set TARGETED_DEVICE_FAMILY to iPhone only (1)
# This removes iPad support
if grep -q "TARGETED_DEVICE_FAMILY" "$PBXPROJ_PATH"; then
    sed -i '' 's/TARGETED_DEVICE_FAMILY = "[^"]*"/TARGETED_DEVICE_FAMILY = "1"/g' "$PBXPROJ_PATH"
    sed -i '' 's/TARGETED_DEVICE_FAMILY = [0-9,]*;/TARGETED_DEVICE_FAMILY = 1;/g' "$PBXPROJ_PATH"
    echo "  Set TARGETED_DEVICE_FAMILY = 1 (iPhone only)"
fi

# 2. Set App Icon asset catalog
if grep -q "ASSETCATALOG_COMPILER_APPICON_NAME" "$PBXPROJ_PATH"; then
    sed -i '' 's/ASSETCATALOG_COMPILER_APPICON_NAME = [^;]*;/ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;/g' "$PBXPROJ_PATH"
    echo "  Set ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon"
else
    # Add the setting to each buildSettings block
    sed -i '' '/buildSettings = {/a\
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
' "$PBXPROJ_PATH"
    echo "  Added ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon"
fi

# 3. Update MARKETING_VERSION (display version)
if grep -q "MARKETING_VERSION" "$PBXPROJ_PATH"; then
    sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $VERSION;/g" "$PBXPROJ_PATH"
    echo "  Set MARKETING_VERSION = $VERSION"
else
    sed -i '' "/buildSettings = {/a\\
				MARKETING_VERSION = $VERSION;
" "$PBXPROJ_PATH"
    echo "  Added MARKETING_VERSION = $VERSION"
fi

# 4. Update CURRENT_PROJECT_VERSION (build number)
if grep -q "CURRENT_PROJECT_VERSION" "$PBXPROJ_PATH"; then
    sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $VERSION;/g" "$PBXPROJ_PATH"
    echo "  Set CURRENT_PROJECT_VERSION = $VERSION"
else
    sed -i '' "/buildSettings = {/a\\
				CURRENT_PROJECT_VERSION = $VERSION;
" "$PBXPROJ_PATH"
    echo "  Added CURRENT_PROJECT_VERSION = $VERSION"
fi

# 5. Ensure SUPPORTS_MACCATALYST is NO
if grep -q "SUPPORTS_MACCATALYST" "$PBXPROJ_PATH"; then
    sed -i '' 's/SUPPORTS_MACCATALYST = [^;]*;/SUPPORTS_MACCATALYST = NO;/g' "$PBXPROJ_PATH"
    echo "  Set SUPPORTS_MACCATALYST = NO"
fi

# 6. Ensure PRODUCT_BUNDLE_IDENTIFIER is correct (lowercase)
if grep -q "PRODUCT_BUNDLE_IDENTIFIER" "$PBXPROJ_PATH"; then
    sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = com.kvakkefly.fyrlysar;/g' "$PBXPROJ_PATH"
    echo "  Set PRODUCT_BUNDLE_IDENTIFIER = com.kvakkefly.fyrlysar"
fi

echo ""
echo "Xcode project patched successfully!"
echo "Backup saved to: $PBXPROJ_PATH.backup"

