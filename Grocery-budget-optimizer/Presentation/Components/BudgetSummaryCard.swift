import SwiftUI

struct BudgetSummaryCard: View {
    let summary: BudgetSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Budget")
                .font(.headline)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Budget.amount)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    CurrencyText(value: summary.budget.amount)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(L10n.Budget.spent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    CurrencyText(value: summary.totalSpent)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Budget.remaining)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    CurrencyText(value: summary.remainingAmount)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(summary.remainingAmount >= 0 ? .green : .red)
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
