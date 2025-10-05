# Barcode Scanner Setup Instructions

## Camera Permission Configuration

Since this project uses the modern iOS app structure without a physical Info.plist file, you need to add the camera usage permission through Xcode's project settings:

### Steps to Add Camera Permission:

1. Open the project in Xcode
2. Select the **Grocery-budget-optimizer** target in the project navigator
3. Go to the **Info** tab
4. Under **Custom iOS Target Properties**, click the **+** button
5. Add the following key-value pair:
   - **Key**: `Privacy - Camera Usage Description` (or `NSCameraUsageDescription`)
   - **Type**: String
   - **Value**: `We need camera access to scan product barcodes and help you add items quickly to your shopping list.`

### Alternative: Add to Info.plist manually

If your project has an Info.plist file, add this XML:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan product barcodes and help you add items quickly to your shopping list.</string>
```

### Verification

After adding the permission:
1. Build and run the app
2. Tap the "Scan Product" button on the Home screen
3. The app should request camera permission
4. Grant permission to use the barcode scanner

## Localized Permission Messages

For a better user experience, you can add localized permission messages:

### Russian (ru)
```
Нам нужен доступ к камере для сканирования штрих-кодов товаров.
```

### Hebrew (he)
```
אנחנו צריכים גישה למצלמה כדי לסרוק ברקודים של מוצרים.
```

### Ukrainian (uk)
```
Нам потрібен доступ до камери для сканування штрих-кодів товарів.
```

## Testing the Scanner

Test barcodes:
- **3017620422003** - Nutella (EAN-13)
- **737628064502** - Coca-Cola (UPC-A)
- **00012345678905** - Generic UPC

The scanner supports: EAN-13, EAN-8, UPC-A, Code 128, Code 39, and QR codes.
