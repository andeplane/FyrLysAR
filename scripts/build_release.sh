#!/bin/bash
#
# Build script for fyrlysar iOS app
#
# Usage:
#   ./scripts/build_release.sh                 # Full build (generate + patch + build)
#   ./scripts/build_release.sh --generate-only # Only generate Xcode project
#   ./scripts/build_release.sh --build-only    # Only patch and build (assumes Xcode project exists)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build/Qt_6_6_1_for_iOS-Release"
VERSION=$(cat "$PROJECT_ROOT/APP_VERSION" | tr -d '[:space:]')

# Qt installation path - adjust this based on your system
QT_PATH="${QT_PATH:-$HOME/Qt/6.6.1/ios}"
QMAKE="$QT_PATH/bin/qmake"

echo "Building fyrlysar version $VERSION"
echo "Project root: $PROJECT_ROOT"
echo "Build directory: $BUILD_DIR"

generate_xcode_project() {
    echo ""
    echo "=== Generating Xcode project with qmake ==="
    
    if [ ! -f "$QMAKE" ]; then
        echo "Error: qmake not found at $QMAKE"
        echo "Please set QT_PATH environment variable to your Qt iOS installation"
        echo "Example: export QT_PATH=\$HOME/Qt/6.6.1/ios"
        exit 1
    fi
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    "$QMAKE" "$PROJECT_ROOT/fyrlysar.pro" \
        -spec macx-ios-clang \
        CONFIG+=release \
        CONFIG+=iphoneos \
        CONFIG+=device
    
    echo "Xcode project generated at: $BUILD_DIR/fyrlysar.xcodeproj"
}

patch_xcode_project() {
    echo ""
    echo "=== Patching Xcode project ==="
    
    PATCH_SCRIPT="$SCRIPT_DIR/patch_xcodeproj.sh"
    
    if [ ! -f "$PATCH_SCRIPT" ]; then
        echo "Error: Patch script not found at $PATCH_SCRIPT"
        exit 1
    fi
    
    "$PATCH_SCRIPT" "$BUILD_DIR/fyrlysar.xcodeproj" "$VERSION"
}

build_project() {
    echo ""
    echo "=== Building project ==="
    
    cd "$BUILD_DIR"
    
    xcodebuild \
        -project fyrlysar.xcodeproj \
        -scheme fyrlysar \
        -configuration Release \
        -destination 'generic/platform=iOS' \
        CODE_SIGN_IDENTITY=- \
        build
    
    echo ""
    echo "Build completed successfully!"
}

# Parse arguments
GENERATE_ONLY=false
BUILD_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --generate-only)
            GENERATE_ONLY=true
            shift
            ;;
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Execute based on flags
if [ "$GENERATE_ONLY" = true ]; then
    generate_xcode_project
elif [ "$BUILD_ONLY" = true ]; then
    patch_xcode_project
    # Note: actual build is handled by fastlane's build_app
else
    # Full build
    generate_xcode_project
    patch_xcode_project
    build_project
fi

echo ""
echo "Done!"

