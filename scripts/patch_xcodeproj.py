#!/usr/bin/env python3
#
# Patches the Qt-generated Xcode project for iOS App Store submission
# Uses Python's plistlib to safely parse and modify .pbxproj files
#
# Usage: python3 patch_xcodeproj.py <path_to_xcodeproj> <version>
#
# This script:
# 1. Sets supported destinations to iPhone only (removes iPad, Mac Catalyst)
# 2. Sets the App Icon to use AppIcon asset catalog
# 3. Updates version numbers
#

import sys
import os
import plistlib
import shutil
from pathlib import Path


def update_build_settings(project, setting_key, setting_value, target_name="fyrlysar"):
    """Update a build setting for all configurations of a specific target."""
    updated_count = 0
    
    # Find the target
    targets = project.get("objects", {})
    target_id = None
    
    for obj_id, obj_data in targets.items():
        if isinstance(obj_data, dict) and obj_data.get("isa") == "PBXNativeTarget":
            if obj_data.get("name") == target_name:
                target_id = obj_id
                break
    
    if not target_id:
        print(f"  Warning: Target '{target_name}' not found")
        return updated_count
    
    # Get build configuration list for the target
    target = targets[target_id]
    build_configuration_list_id = target.get("buildConfigurationList")
    
    if not build_configuration_list_id:
        print(f"  Warning: No build configuration list found for target")
        return updated_count
    
    # Get the build configuration list
    build_config_list = targets.get(build_configuration_list_id, {})
    build_configurations = build_config_list.get("buildConfigurations", [])
    
    # Update each build configuration
    for config_id in build_configurations:
        config = targets.get(config_id, {})
        build_settings = config.get("buildSettings", {})
        
        old_value = build_settings.get(setting_key)
        build_settings[setting_key] = setting_value
        
        if old_value != setting_value:
            updated_count += 1
            if old_value is not None:
                print(f"    Updated {setting_key}: {old_value} -> {setting_value}")
            else:
                print(f"    Added {setting_key}: {setting_value}")
    
    return updated_count


def patch_project(xcodeproj_path, version):
    """Patch the Xcode project with required settings."""
    pbxproj_path = os.path.join(xcodeproj_path, "project.pbxproj")
    
    if not os.path.exists(pbxproj_path):
        print(f"Error: project.pbxproj not found at {pbxproj_path}")
        sys.exit(1)
    
    # Create backup
    backup_path = f"{pbxproj_path}.backup"
    shutil.copy2(pbxproj_path, backup_path)
    print(f"Backup created: {backup_path}")
    
    # Read the project file
    # .pbxproj files can be ASCII or XML plist format
    # Use plutil (macOS tool) to convert to XML format for reliable parsing
    import subprocess
    import tempfile
    
    try:
        # Try reading directly as binary (works for XML/binary plists)
        with open(pbxproj_path, 'rb') as f:
            project = plistlib.load(f)
    except:
        # If that fails, convert ASCII plist to XML using plutil
        try:
            with tempfile.NamedTemporaryFile(mode='wb', delete=False, suffix='.plist') as tmp:
                tmp_path = tmp.name
            try:
                # Convert ASCII plist to XML format using plutil
                subprocess.run(['plutil', '-convert', 'xml1', '-o', tmp_path, pbxproj_path], 
                             check=True, capture_output=True)
                with open(tmp_path, 'rb') as f:
                    project = plistlib.load(f)
            finally:
                if os.path.exists(tmp_path):
                    os.unlink(tmp_path)
        except Exception as e:
            print(f"Error reading project file: {e}")
            print("Note: Ensure plutil is available (macOS) or project.pbxproj is in XML format")
            sys.exit(1)
    
    print("Patching project.pbxproj...")
    
    # 1. Set TARGETED_DEVICE_FAMILY to iPhone only (1)
    count = update_build_settings(project, "TARGETED_DEVICE_FAMILY", "1")
    if count > 0:
        print(f"  Set TARGETED_DEVICE_FAMILY = 1 (iPhone only) in {count} configuration(s)")
    
    # 2. Set App Icon asset catalog
    count = update_build_settings(project, "ASSETCATALOG_COMPILER_APPICON_NAME", "AppIcon")
    if count > 0:
        print(f"  Set ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon in {count} configuration(s)")
    
    # 3. Update MARKETING_VERSION (display version)
    count = update_build_settings(project, "MARKETING_VERSION", version)
    if count > 0:
        print(f"  Set MARKETING_VERSION = {version} in {count} configuration(s)")
    
    # 4. Update CURRENT_PROJECT_VERSION (build number)
    count = update_build_settings(project, "CURRENT_PROJECT_VERSION", version)
    if count > 0:
        print(f"  Set CURRENT_PROJECT_VERSION = {version} in {count} configuration(s)")
    
    # 5. Ensure SUPPORTS_MACCATALYST is NO
    count = update_build_settings(project, "SUPPORTS_MACCATALYST", "NO")
    if count > 0:
        print(f"  Set SUPPORTS_MACCATALYST = NO in {count} configuration(s)")
    
    # 6. Ensure PRODUCT_BUNDLE_IDENTIFIER is correct (lowercase)
    count = update_build_settings(project, "PRODUCT_BUNDLE_IDENTIFIER", "com.kvakkefly.fyrlysar")
    if count > 0:
        print(f"  Set PRODUCT_BUNDLE_IDENTIFIER = com.kvakkefly.fyrlysar in {count} configuration(s)")
    
    # 7. Enable automatic code signing (Fastlane will manage certificates)
    count = update_build_settings(project, "CODE_SIGN_STYLE", "Automatic")
    if count > 0:
        print(f"  Set CODE_SIGN_STYLE = Automatic in {count} configuration(s)")
    
    # 8. Set development team if provided via environment variable
    # Fastlane will automatically set this when using App Store Connect API key
    # But we can set it here if FASTLANE_TEAM_ID is provided
    import os
    team_id = os.environ.get('FASTLANE_TEAM_ID')
    if team_id:
        count = update_build_settings(project, "DEVELOPMENT_TEAM", team_id)
        if count > 0:
            print(f"  Set DEVELOPMENT_TEAM = {team_id} in {count} configuration(s)")
    else:
        # Set empty team - Fastlane will populate it automatically
        count = update_build_settings(project, "DEVELOPMENT_TEAM", "")
        if count > 0:
            print(f"  Set DEVELOPMENT_TEAM = (empty, will be set by Fastlane) in {count} configuration(s)")
    
    # Write the modified project back
    # Use XML format which Xcode can read (and is more standard)
    try:
        # Write as XML plist format (Xcode can read this)
        with open(pbxproj_path, 'wb') as f:
            # Use XML format for better compatibility
            if hasattr(plistlib, 'FMT_XML'):
                plistlib.dump(project, f, fmt=plistlib.FMT_XML)
            else:
                # Fallback for older Python versions
                plistlib.dump(project, f)
    except Exception as e:
        print(f"Error writing project file: {e}")
        # Restore backup
        shutil.copy2(backup_path, pbxproj_path)
        sys.exit(1)
    
    print("")
    print("Xcode project patched successfully!")


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <path_to_xcodeproj> <version>")
        sys.exit(1)
    
    xcodeproj_path = sys.argv[1]
    version = sys.argv[2]
    
    print(f"Patching Xcode project: {xcodeproj_path}")
    print(f"Version: {version}")
    print("")
    
    patch_project(xcodeproj_path, version)


if __name__ == "__main__":
    main()

