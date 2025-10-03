import SwiftUI
import Charts

struct BudgetView: View {
    @StateObject private var viewModel = BudgetViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let summary = viewModel.currentBudgetSummary {
                        // Budget Overview Card
                        budgetOverviewCard(summary: summary)

                        // Spending by Category Chart
                        spendingByCategoryChart(summary: summary)

                        // Daily Spending Trend
                        dailySpendingChart

                        // Category Breakdown List
                        categoryBreakdownList(summary: summary)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showCreateBudget()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .task {
                await viewModel.loadBudget()
            }
        }
    }

    private func budgetOverviewCard(summary: BudgetSummary) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(summary.budget.name)
                        .font(.headline)
                    Text("\(summary.budget.startDate.formatted(date: .abbreviated, time: .omitted)) - \(summary.budget.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 30) {
                budgetStatItem(
                    title: "Budget",
                    value: summary.budget.amount,
                    color: .blue
                )

                budgetStatItem(
                    title: "Spent",
                    value: summary.totalSpent,
                    color: .orange
                )

                budgetStatItem(
                    title: "Remaining",
                    value: summary.remainingAmount,
                    color: summary.remainingAmount > 0 ? .green : .red
                )
            }

            // Progress
            VStack(spacing: 8) {
                HStack {
                    Text("\(Int(summary.percentageUsed))% Used")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(summary.daysRemaining) days left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: summary.percentageUsed / 100)
                    .tint(summary.isOnTrack ? .green : .red)
            }

            if !summary.isOnTrack {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Projected to exceed budget by \((summary.projectedTotal - summary.budget.amount), format: .currency(code: "USD"))")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func budgetStatItem(title: String, value: Decimal, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: "USD"))
                .font(.headline)
                .foregroundStyle(color)
        }
    }

    private func spendingByCategoryChart(summary: BudgetSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)

            Chart {
                ForEach(Array(summary.spendingByCategory.sorted(by: { $0.value > $1.value })), id: \.key) { category, amount in
                    SectorMark(
                        angle: .value("Amount", Double(truncating: amount as NSDecimalNumber)),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Category", category))
                }
            }
            .frame(height: 250)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var dailySpendingChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Spending")
                .font(.headline)

            if !viewModel.dailySpending.isEmpty {
                Chart(viewModel.dailySpending) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Amount", Double(truncating: data.amount as NSDecimalNumber))
                    )
                    .foregroundStyle(.blue.gradient)

                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Amount", Double(truncating: data.amount as NSDecimalNumber))
                    )
                    .foregroundStyle(.blue.opacity(0.1).gradient)
                }
                .frame(height: 200)
            } else {
                Text("No spending data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func categoryBreakdownList(summary: BudgetSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)

            ForEach(Array(summary.spendingByCategory.sorted(by: { $0.value > $1.value })), id: \.key) { category, amount in
                HStack {
                    Text(category)
                        .font(.subheadline)

                    Spacer()

                    Text(amount, format: .currency(code: "USD"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 80))
                .foregroundStyle(.gray.gradient)

            Text("No Active Budget")
                .font(.title2)
                .fontWeight(.semibold)

            Button("Create Budget") {
                viewModel.showCreateBudget()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    BudgetView()
}
