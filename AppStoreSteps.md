# Publish to app store step by step guide

1. Open the project in Qt Creator
2. Build a release version of the app
3. Navigate to build folder and open FyrLysAR.xcodeproj in XCode
4. Remove all Supported Destinations that are not iPhone
5. Ensure that Bundle Identifier is all lowercase com.kvakkefly.fyrlysar
6. Click File -> New -> File from template, choose Asset Catalog and name it AppIcon
7. Click the plus button -> iOS -> iOS App icon and drag in the non transparent logo
8. It may happen that the Asset Catalog file is not added to the project. If this is the case, find it in Finder and drag'n drop into list of files in XCode.
9. Click the main project root item in file list, go to General and update App Icon to be AppIcon

You should now be able to run Product -> Archive that validates the app bundle.
