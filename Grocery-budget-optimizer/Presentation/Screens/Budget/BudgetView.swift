import SwiftUI
import Charts
import Combine

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
            .sheet(isPresented: $viewModel.showingCreateBudget) {
                CreateBudgetSheet(onCreated: {
                    Task {
                        await viewModel.refreshBudget()
                    }
                })
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

            if !summary.spendingByCategory.isEmpty {
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
            } else {
                Text("No spending data yet. Add expenses to see category breakdown.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
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
                Text("No spending data yet. Add expenses to see daily trends.")
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

            if !summary.spendingByCategory.isEmpty {
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
            } else {
                Text("No category data yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
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

struct CreateBudgetSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var budgetName = ""
    @State private var budgetAmount = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()

    let onCreated: () -> Void

    private let createBudgetUseCase = DIContainer.shared.createBudgetUseCase

    private var isFormValid: Bool {
        !budgetName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !budgetAmount.trimmingCharacters(in: .whitespaces).isEmpty &&
        endDate > startDate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Information") {
                    TextField("Budget Name", text: $budgetName)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Total Amount", text: $budgetAmount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Duration") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)

                    if endDate > startDate {
                        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
                        HStack {
                            Text("Duration")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(days) days")
                                .fontWeight(.medium)
                        }
                    }
                }

                Section {
                    Text("Category-specific budgets can be added after creating the main budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Create Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createBudget()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }

    private func createBudget() {
        guard let amount = Decimal(string: budgetAmount) else { return }
        isLoading = true

        let budget = Budget(
            name: budgetName.trimmingCharacters(in: .whitespaces),
            amount: amount,
            startDate: startDate,
            endDate: endDate,
            isActive: true
        )

        createBudgetUseCase.execute(budget)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Error creating budget: \(error)")
                    }
                },
                receiveValue: { [self] _ in
                    print("✅ Budget created successfully")
                    onCreated()
                    dismiss()
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    BudgetView()
}
