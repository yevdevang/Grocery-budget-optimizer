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
    @State private var productImage: UIImage?
    @State private var cancellable: AnyCancellable?

    private let repository = DIContainer.shared.groceryItemRepository

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Scanner.productInfo) {
                    if let image = productImage {
                        HStack {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Spacer()
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
            print("📥 Loading product image from: \(imageUrlString)")
            let (data, _) = try await URLSession.shared.data(from: url)
            productImage = UIImage(data: data)
            print("✅ Product image loaded successfully")
        } catch {
            print("❌ Failed to load product image: \(error)")
        }
    }

    private func addItem() {
        isLoading = true

        let item = productInfo.toGroceryItem()

        print("💾 Adding scanned item: \(item.name)")

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
