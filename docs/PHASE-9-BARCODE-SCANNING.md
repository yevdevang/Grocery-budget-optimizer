# Phase 9: Barcode Scanning & Product Discovery

## 📋 Overview

Implement barcode/QR code scanning functionality that integrates with the Open Food Facts API to automatically populate product information when users scan grocery items.

**Duration**: 2-3 days
**Dependencies**: Phase 3 (Core Features), Phase 5 (UI/UX)

---

## 🎯 Objectives

- ✅ Integrate Open Food Facts API
- ✅ Implement camera-based barcode scanning
- ✅ Create product detail preview from scanned data
- ✅ Map API data to GroceryItem entity
- ✅ Add barcode field to existing items
- ✅ Handle camera permissions gracefully
- ✅ Support offline scenarios
- ✅ Multi-language product data support

---

## 🌐 Open Food Facts API Integration

### API Endpoint

```
GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json
```

### Supported Barcode Formats
- **EAN-13**: Standard European/International barcodes (13 digits)
- **UPC-A**: North American barcodes (12 digits)
- **EAN-8**: Short European barcodes (8 digits)
- **QR Codes**: Can contain product URLs or barcode numbers

### Example Response Structure

```json
{
  "code": "3017620422003",
  "product": {
    "product_name": "Nutella",
    "brands": "Ferrero",
    "categories": "Spreads",
    "quantity": "400g",
    "image_url": "https://images.openfoodfacts.org/...",
    "nutriments": {
      "energy-kcal_100g": 539,
      "fat_100g": 30.9,
      "carbohydrates_100g": 57.5,
      "proteins_100g": 6.3
    },
    "stores": "Walmart, Target",
    "countries": "United States"
  },
  "status": 1,
  "status_verbose": "product found"
}
```

### API Response Mapping

| Open Food Facts Field | GroceryItem Field | Transformation |
|----------------------|-------------------|----------------|
| `product.product_name` | `name` | Direct mapping |
| `product.brands` | `brand` | Use first brand if multiple |
| `product.categories` | `category` | Map to app categories |
| `product.quantity` | `unit` | Parse quantity string |
| `product.image_url` | `imageData` | Download and convert to Data |
| `code` | `barcode` | Direct mapping (new field) |

---

## 📊 Data Models

### Open Food Facts Response Models

Create `Data/Network/Models/OpenFoodFactsResponse.swift`:

```swift
import Foundation

struct OpenFoodFactsResponse: Codable {
    let code: String
    let product: Product?
    let status: Int
    let statusVerbose: String

    enum CodingKeys: String, CodingKey {
        case code
        case product
        case status
        case statusVerbose = "status_verbose"
    }

    struct Product: Codable {
        let productName: String?
        let brands: String?
        let categories: String?
        let quantity: String?
        let imageUrl: String?
        let nutriments: Nutriments?
        let stores: String?
        let countries: String?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands
            case categories
            case quantity
            case imageUrl = "image_url"
            case nutriments
            case stores
            case countries
        }

        struct Nutriments: Codable {
            let energyKcal100g: Double?
            let fat100g: Double?
            let carbohydrates100g: Double?
            let proteins100g: Double?

            enum CodingKeys: String, CodingKey {
                case energyKcal100g = "energy-kcal_100g"
                case fat100g = "fat_100g"
                case carbohydrates100g = "carbohydrates_100g"
                case proteins100g = "proteins_100g"
            }
        }
    }

    var isFound: Bool {
        status == 1 && product != nil
    }
}

struct ScannedProductInfo {
    let barcode: String
    let name: String
    let brand: String?
    let category: String
    let unit: String
    let imageUrl: String?
    let nutritionalInfo: String?

    func toGroceryItem() -> GroceryItem {
        GroceryItem(
            name: name,
            category: mapToAppCategory(category),
            brand: brand,
            unit: unit,
            barcode: barcode
        )
    }

    private func mapToAppCategory(_ apiCategory: String) -> String {
        // Map Open Food Facts categories to app categories
        let categoryLower = apiCategory.lowercased()

        if categoryLower.contains("fruit") || categoryLower.contains("vegetable") {
            return "Produce"
        } else if categoryLower.contains("dairy") || categoryLower.contains("milk") || categoryLower.contains("cheese") {
            return "Dairy"
        } else if categoryLower.contains("meat") || categoryLower.contains("fish") || categoryLower.contains("seafood") {
            return "Meat & Seafood"
        } else if categoryLower.contains("beverage") || categoryLower.contains("drink") {
            return "Beverages"
        } else if categoryLower.contains("frozen") {
            return "Frozen"
        } else if categoryLower.contains("bread") || categoryLower.contains("bakery") {
            return "Bakery"
        } else {
            return "Pantry"
        }
    }
}
```

### Updated GroceryItem Entity

Update `Domain/Entities/GroceryItem.swift`:

```swift
struct GroceryItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String
    var brand: String?
    var unit: String
    var notes: String?
    var imageData: Data?
    var barcode: String?  // NEW FIELD
    var averagePrice: Decimal
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        brand: String? = nil,
        unit: String,
        notes: String? = nil,
        imageData: Data? = nil,
        barcode: String? = nil,  // NEW PARAMETER
        averagePrice: Decimal = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.brand = brand
        self.unit = unit
        self.notes = notes
        self.imageData = imageData
        self.barcode = barcode
        self.averagePrice = averagePrice
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

---

## 🌐 Network Service

Create `Data/Network/OpenFoodFactsService.swift`:

```swift
import Foundation
import Combine

protocol OpenFoodFactsServiceProtocol {
    func fetchProduct(barcode: String) -> AnyPublisher<ScannedProductInfo?, Error>
}

class OpenFoodFactsService: OpenFoodFactsServiceProtocol {
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProduct(barcode: String) -> AnyPublisher<ScannedProductInfo?, Error> {
        guard let url = URL(string: "\(baseURL)/\(barcode).json") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenFoodFactsResponse.self, decoder: JSONDecoder())
            .map { response -> ScannedProductInfo? in
                guard response.isFound,
                      let product = response.product,
                      let productName = product.productName else {
                    return nil
                }

                return ScannedProductInfo(
                    barcode: response.code,
                    name: productName,
                    brand: product.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
                    category: product.categories?.components(separatedBy: ",").first ?? "Other",
                    unit: product.quantity ?? "1 unit",
                    imageUrl: product.imageUrl,
                    nutritionalInfo: self.formatNutritionalInfo(product.nutriments)
                )
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func formatNutritionalInfo(_ nutriments: OpenFoodFactsResponse.Product.Nutriments?) -> String? {
        guard let nutriments = nutriments else { return nil }

        var info: [String] = []

        if let calories = nutriments.energyKcal100g {
            info.append("Calories: \(Int(calories)) kcal/100g")
        }
        if let fat = nutriments.fat100g {
            info.append("Fat: \(String(format: "%.1f", fat))g/100g")
        }
        if let carbs = nutriments.carbohydrates100g {
            info.append("Carbs: \(String(format: "%.1f", carbs))g/100g")
        }
        if let protein = nutriments.proteins100g {
            info.append("Protein: \(String(format: "%.1f", protein))g/100g")
        }

        return info.isEmpty ? nil : info.joined(separator: "\n")
    }
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case productNotFound
}
```

---

## 📱 Camera Integration & Barcode Scanning

### Camera Permissions

Add to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan product barcodes and help you add items quickly to your shopping list.</string>
```

### Barcode Scanner View

Create `Presentation/Screens/Scanner/BarcodeScannerView.swift`:

```swift
import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @StateObject private var viewModel: BarcodeScannerViewModel
    @Environment(\.dismiss) private var dismiss

    init(onBarcodeScanned: @escaping (String) -> Void) {
        _viewModel = StateObject(wrappedValue: BarcodeScannerViewModel(onBarcodeScanned: onBarcodeScanned))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()

                // Scanning overlay
                VStack {
                    Spacer()

                    // Targeting rectangle
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 280, height: 180)
                        .overlay {
                            if viewModel.isScanning {
                                // Scanning animation
                                Rectangle()
                                    .fill(Color.green.opacity(0.3))
                                    .frame(height: 2)
                                    .offset(y: viewModel.scanLineOffset)
                            }
                        }

                    Text(L10n.Scanner.instruction)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 20)

                    Spacer()
                }
            }
            .navigationTitle(L10n.Scanner.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.toggleTorch()
                    } label: {
                        Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    }
                }
            }
            .alert(L10n.Scanner.Error.title, isPresented: $viewModel.showError) {
                Button(L10n.Common.ok, role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(viewModel.errorMessage ?? L10n.Scanner.Error.message)
            }
            .onAppear {
                viewModel.startScanning()
            }
            .onDisappear {
                viewModel.stopScanning()
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}
```

---

## 🎯 Use Cases

Create `Domain/UseCases/Product/ScanProductUseCase.swift`:

```swift
import Foundation
import Combine

protocol ScanProductUseCaseProtocol {
    func execute(barcode: String) -> AnyPublisher<ScannedProductInfo?, Error>
}

class ScanProductUseCase: ScanProductUseCaseProtocol {
    private let openFoodFactsService: OpenFoodFactsServiceProtocol

    init(openFoodFactsService: OpenFoodFactsServiceProtocol) {
        self.openFoodFactsService = openFoodFactsService
    }

    func execute(barcode: String) -> AnyPublisher<ScannedProductInfo?, Error> {
        print("🔍 Scanning barcode: \(barcode)")

        return openFoodFactsService.fetchProduct(barcode: barcode)
            .handleEvents(
                receiveOutput: { product in
                    if let product = product {
                        print("✅ Product found: \(product.name)")
                    } else {
                        print("⚠️ Product not found in Open Food Facts database")
                    }
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Error scanning product: \(error)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }
}
```

---

## 🎨 UI Components

### Home View Integration

Update quick actions in `HomeView.swift` to include scanner:

```swift
LazyVGrid(columns: [
    GridItem(.flexible()),
    GridItem(.flexible())
], spacing: 12) {
    // ... existing buttons ...

    QuickActionButton(
        icon: "barcode.viewfinder",
        title: L10n.Home.scanProduct,
        color: .cyan
    ) {
        viewModel.showScanner()
    }
}
```

### Scanned Product Detail View

Create `Presentation/Screens/Scanner/ScannedProductDetailView.swift`:

```swift
import SwiftUI

struct ScannedProductDetailView: View {
    let productInfo: ScannedProductInfo
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var productImage: UIImage?

    private let repository = DIContainer.shared.groceryItemRepository

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Scanner.productInfo) {
                    if let image = productImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    }

                    LabeledContent(L10n.AddItem.name, value: productInfo.name)

                    if let brand = productInfo.brand {
                        LabeledContent(L10n.AddItem.brand, value: brand)
                    }

                    LabeledContent(L10n.AddItem.category, value: productInfo.category)
                    LabeledContent(L10n.AddItem.unit, value: productInfo.unit)
                    LabeledContent(L10n.Scanner.barcode, value: productInfo.barcode)
                }

                if let nutritionalInfo = productInfo.nutritionalInfo {
                    Section(L10n.Scanner.nutritionalInfo) {
                        Text(nutritionalInfo)
                            .font(.caption)
                    }
                }

                Section {
                    Button(action: addItem) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(L10n.Scanner.addToItems)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle(L10n.Scanner.productDetails)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
            }
            .task {
                await loadProductImage()
            }
        }
    }

    private func loadProductImage() async {
        guard let imageUrlString = productInfo.imageUrl,
              let url = URL(string: imageUrlString) else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            productImage = UIImage(data: data)
        } catch {
            print("Failed to load product image: \(error)")
        }
    }

    private func addItem() {
        isLoading = true

        let item = productInfo.toGroceryItem()

        _ = repository.createItem(item)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Error adding scanned item: \(error)")
                    }
                },
                receiveValue: { _ in
                    print("✅ Scanned item added successfully")
                    dismiss()
                }
            )
    }
}
```

---

## 🌍 Localization

Add to `Localizable.strings` for all languages (en, ru, he, uk):

```
/* Scanner */
"scanner.title" = "Scan Barcode";
"scanner.instruction" = "Align barcode within the frame";
"scanner.scanProduct" = "Scan Product";
"scanner.productInfo" = "Product Information";
"scanner.productDetails" = "Product Details";
"scanner.barcode" = "Barcode";
"scanner.nutritionalInfo" = "Nutritional Information";
"scanner.addToItems" = "Add to My Items";
"scanner.error.title" = "Scanner Error";
"scanner.error.message" = "Unable to access camera or scan barcode";
"scanner.error.cameraPermission" = "Camera permission is required to scan barcodes";
"scanner.error.productNotFound" = "Product not found in database";
```

---

## 🔧 Dependency Injection

Update `DIContainer.swift`:

```swift
// Services
lazy var openFoodFactsService: OpenFoodFactsServiceProtocol = {
    OpenFoodFactsService()
}()

// Use Cases
lazy var scanProductUseCase: ScanProductUseCaseProtocol = {
    ScanProductUseCase(openFoodFactsService: openFoodFactsService)
}()
```

---

## ✅ Testing Strategy

### Unit Tests
- Test Open Food Facts API response parsing
- Test category mapping logic
- Test barcode validation
- Test network error handling

### Integration Tests
- Test camera permission flow
- Test barcode scanning with sample barcodes
- Test API integration with known barcodes
- Test offline behavior

### Manual Testing Barcodes
- **3017620422003** - Nutella (EAN-13)
- **00012345678905** - Generic UPC
- **737628064502** - Coca-Cola (UPC-A)

---

## 🚀 Future Enhancements

1. **Scan History**: Track scanned barcodes for quick re-addition
2. **Offline Barcode Database**: Cache common products for offline use
3. **Price Comparison**: Integrate with price APIs
4. **Nutritional Tracking**: Add calorie/macro tracking
5. **Receipt Scanning**: OCR for bulk item addition
6. **Custom Barcode Generation**: Generate barcodes for custom items

---

## 📊 Success Metrics

- ✅ Camera launches successfully
- ✅ Barcodes detected within 2 seconds
- ✅ API response time < 1 second
- ✅ 80%+ successful product matches
- ✅ Graceful handling of unknown products
- ✅ Support for all major barcode formats

---

## 📚 Resources

- [Open Food Facts API Documentation](https://wiki.openfoodfacts.org/API)
- [AVFoundation Barcode Scanning](https://developer.apple.com/documentation/avfoundation/avcaptureoutput)
- [Machine Readable Codes](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput/metadata_object_types/machine-readable_codes)
