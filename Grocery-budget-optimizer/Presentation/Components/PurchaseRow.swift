import SwiftUI

struct PurchaseRow: View {
    let purchase: Purchase

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(purchase.groceryItem.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(purchase.purchaseDate, style: .date)
                    if let storeName = purchase.storeName {
                        Text("•")
                        Text(storeName)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(purchase.totalCost, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Qty: \(purchase.quantity, format: .number)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
