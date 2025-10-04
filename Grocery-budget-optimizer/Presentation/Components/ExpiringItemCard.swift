import SwiftUI

struct ExpiringItemCard: View {
    let item: ExpiringItemInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: urgencyIcon)
                    .foregroundStyle(urgencyColor)

                Spacer()

                Text("\(item.daysRemaining)d")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(urgencyColor)
            }

            Text(item.item.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            Text(item.item.category)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Qty: \(item.tracker.remainingQuantity, format: .number)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 140)
        .background(urgencyColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var urgencyColor: Color {
        switch item.urgency {
        case .expired:
            return .red
        case .useSoon:
            return .orange
        case .moderate:
            return .yellow
        case .fresh:
            return .green
        }
    }

    private var urgencyIcon: String {
        switch item.urgency {
        case .expired:
            return "xmark.circle.fill"
        case .useSoon:
            return "exclamationmark.triangle.fill"
        case .moderate:
            return "clock.fill"
        case .fresh:
            return "checkmark.circle.fill"
        }
    }
}
