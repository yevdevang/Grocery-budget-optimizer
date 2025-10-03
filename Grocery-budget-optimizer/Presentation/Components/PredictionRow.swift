import SwiftUI

struct PredictionRow: View {
    let prediction: ItemPurchasePrediction

    var body: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title3)
                .foregroundStyle(.blue.gradient)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(prediction.item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(prediction.prediction.daysUntilPurchase) days", systemImage: "calendar")
                    Label("\(Int(prediction.prediction.confidence * 100))%", systemImage: "chart.bar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(prediction.item.averagePrice, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Qty: \(prediction.prediction.recommendedQuantity, format: .number)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
