# CodeScanner Installation Guide

## Step 1: Add Swift Package Dependency

You need to add the CodeScanner package to your Xcode project. Follow these steps:

### In Xcode:

1. **Open your project** in Xcode (if not already open):
   - The project should already be open

2. **Add Package Dependency**:
   - Click on the project file `Grocery-budget-optimizer` in the Project Navigator (left sidebar)
   - Select the `Grocery-budget-optimizer` target
   - Go to the **"Package Dependencies"** tab
   - Click the **"+"** button at the bottom

3. **Search for CodeScanner**:
   - In the search field (top right), paste this URL:
     ```
     https://github.com/twostraws/CodeScanner
     ```
   - Press Enter/Return

4. **Add the Package**:
   - Select the `CodeScanner` package from the results
   - Keep the default "Dependency Rule" (usually "Up to Next Major Version")
   - Click **"Add Package"**

5. **Add to Target**:
   - In the "Choose Package Products" dialog, make sure `CodeScanner` is checked
   - Make sure it's added to the `Grocery-budget-optimizer` target
   - Click **"Add Package"**

6. **Wait for Installation**:
   - Xcode will download and resolve the package dependencies
   - Wait for the progress indicator to complete

## Step 2: Verify Installation

After installation, build the project to verify:

```bash
# From terminal
xcodebuild -project Grocery-budget-optimizer.xcodeproj -scheme Grocery-budget-optimizer build
```

Or in Xcode: **Cmd + B**

## What Changed

✅ **BarcodeScannerView.swift** - Updated to use CodeScanner instead of AVFoundation
- Simplified from ~130 lines to ~100 lines
- Removed complex camera setup code
- Removed CameraPreview UIViewRepresentable
- Built-in viewfinder and scanning UI
- Cleaner, more maintainable code

⚠️ **BarcodeScannerViewModel.swift** - Can be deleted (no longer needed)
- All scanning logic is now handled by CodeScanner
- 176 lines of code removed!

## Benefits of CodeScanner

✅ **Simpler Code**: ~200 lines of code removed
✅ **Better UX**: Professional viewfinder built-in
✅ **Maintained Library**: Regular updates from Paul Hudson (Hacking with Swift)
✅ **SwiftUI Native**: Designed for SwiftUI from the ground up
✅ **Less Bugs**: Well-tested by thousands of developers
✅ **Torch Support**: Still have flashlight toggle functionality

## Supported Barcode Types

The implementation now supports:
- EAN-13 (most common grocery barcodes)
- EAN-8
- UPC-E
- Code 128
- Code 39
- QR Codes

## Next Steps

After installing the package:
1. Build the project (Cmd + B)
2. You can optionally delete `BarcodeScannerViewModel.swift` (no longer used)
3. Test the scanner in the app

## Troubleshooting

If you get build errors:
1. Clean build folder: **Product → Clean Build Folder** (Shift + Cmd + K)
2. Restart Xcode
3. Make sure the package was added to the correct target
