import SwiftUI

struct BudgetSummaryCard: View {
    let summary: BudgetSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Budget")
                .font(.headline)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.budget.amount, format: .currency(code: "USD"))
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.totalSpent, format: .currency(code: "USD"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(summary.percentageUsed > 80 ? .red : .primary)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.remainingAmount, format: .currency(code: "USD"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(summary.remainingAmount > 0 ? .green : .red)
                }
            }

            ProgressView(value: summary.percentageUsed / 100)
                .tint(summary.isOnTrack ? .green : .red)

            HStack {
                Text("\(Int(summary.percentageUsed))% used")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(summary.daysRemaining) days left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
