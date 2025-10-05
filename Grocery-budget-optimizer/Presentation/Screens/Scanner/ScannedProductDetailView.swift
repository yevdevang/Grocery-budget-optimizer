//
//  ScannedProductDetailView.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 05/10/2025.
//

import SwiftUI
import Combine

struct ScannedProductDetailView: View {
    let productInfo: ScannedProductInfo
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var cancellable: AnyCancellable?
    @State private var price: String = ""
    @State private var quantity: String = "1"
    @ObservedObject private var currencyManager = CurrencyManager.shared

    private let repository = DIContainer.shared.groceryItemRepository

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Scanner.productInfo) {
                    if let imageUrlString = productInfo.imageUrl,
                       let url = URL(string: imageUrlString) {
                        HStack {
                            Spacer()
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    VStack {
                                        ProgressView()
                                        Text("Loading image...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .onAppear {
                                        print("📥 Loading image from: \(url.absoluteString)")
                                    }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .onAppear {
                                            print("✅ Image loaded successfully")
                                        }
                                case .failure(let error):
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundStyle(.gray)
                                        Text("Failed to load image")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                    .onAppear {
                                        print("❌ Image failed to load: \(error.localizedDescription)")
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxHeight: 200)
                            Spacer()
                        }
                    } else {
                        Text("No image available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .onAppear {
                                print("⚠️ No image URL provided for product: \(productInfo.name)")
                            }
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
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Purchase Details") {
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(currencyManager.currentCurrency.symbol)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("1", text: $quantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
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
        }
    }

    private func addItem() {
        isLoading = true
        
        Task {
            var imageData: Data?
            
            // Download image if available
            if let imageUrlString = productInfo.imageUrl,
               let url = URL(string: imageUrlString) {
                do {
                    print("📥 Downloading product image...")
                    let (data, _) = try await URLSession.shared.data(from: url)
                    imageData = data
                    print("✅ Product image downloaded successfully (\(data.count) bytes)")
                } catch {
                    print("⚠️ Failed to download product image: \(error.localizedDescription)")
                    // Continue without image
                }
            }
            
            var item = productInfo.toGroceryItem(imageData: imageData)
            
            // Add price if entered
            if let priceValue = Decimal(string: price), priceValue > 0 {
                item.averagePrice = priceValue
                print("💰 Price set to: \(priceValue)")
            }
            
            if let imgData = item.imageData {
                print("✅ Item has imageData: \(imgData.count) bytes")
            } else {
                print("⚠️ Item has NO imageData!")
            }
            
            print("💾 Adding scanned item: \(item.name) (Qty: \(quantity))")
            
            await MainActor.run {
                cancellable = repository.createItem(item)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { [self] completion in
                            isLoading = false
                            if case .failure(let error) = completion {
                                print("❌ Error adding scanned item: \(error)")
                            }
                            cancellable?.cancel()
                        },
                        receiveValue: { [self] _ in
                            print("✅ Scanned item added successfully")
                            dismiss()
                        }
                    )
            }
        }
    }
}

#Preview {
    ScannedProductDetailView(
        productInfo: ScannedProductInfo(
            barcode: "3017620422003",
            name: "Nutella",
            brand: "Ferrero",
            category: "Spreads",
            unit: "400g",
            imageUrl: nil,
            nutritionalInfo: "Calories: 539 kcal/100g\nFat: 30.9g/100g\nCarbs: 57.5g/100g\nProtein: 6.3g/100g"
        )
    )
}
