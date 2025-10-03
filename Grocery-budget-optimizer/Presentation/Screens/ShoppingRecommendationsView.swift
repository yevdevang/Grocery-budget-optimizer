//
//  ShoppingRecommendationsView.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import SwiftUI

struct ShoppingRecommendationsView: View {
    @StateObject private var mlManager = MLModelManager()
    @State private var budget: String = "100"
    @State private var householdSize: Int = 2
    @State private var insights: ShoppingInsights?
    @State private var isGenerating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shopping Assistant")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Text("Budget:")
                            .fontWeight(.medium)
                        TextField("Enter budget", text: $budget)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("$")
                    }

                    HStack {
                        Text("Household Size:")
                            .fontWeight(.medium)
                        Stepper("\(householdSize) people", value: $householdSize, in: 1...10)
                    }

                    Button(action: generateRecommendations) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "brain")
                                Text("Generate AI Recommendations")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isGenerating || budget.isEmpty)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Results Section
                if let insights = insights {
                    // Budget Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Budget Overview")
                            .font(.headline)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Cost")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(formatPrice(insights.totalEstimatedCost))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("Budget Used")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.0f", insights.budgetUtilizationPercentage))%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(insights.isOverBudget ? .red : .green)
                            }
                        }

                        ProgressView(value: min(Double(truncating: insights.budgetUtilization as NSNumber), 1.0))
                            .tint(insights.isOverBudget ? .red : .green)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Recommendations
                    if !insights.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                Text("AI Recommendations")
                                    .font(.headline)
                            }

                            ForEach(insights.recommendations, id: \.itemName) { recommendation in
                                RecommendationCard(
                                    recommendation: recommendation,
                                    priceAnalysis: insights.priceAnalyses[recommendation.itemName]
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Smart Suggestions
                    if !insights.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                Text("Smart Suggestions")
                                    .font(.headline)
                            }

                            ForEach(insights.suggestions, id: \.itemName) { suggestion in
                                SuggestionCard(suggestion: suggestion)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("AI Shopping Assistant")
        .navigationBarTitleDisplayMode(.large)
    }

    private func generateRecommendations() {
        guard let budgetValue = Decimal(string: budget) else { return }

        isGenerating = true

        // Simulate async operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            insights = mlManager.generateShoppingInsights(
                budget: budgetValue,
                householdSize: householdSize,
                currentPantry: [],
                preferences: [:]
            )
            isGenerating = false
        }
    }
}

struct RecommendationCard: View {
    let recommendation: ShoppingListRecommendation
    let priceAnalysis: PriceAnalysis?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(recommendation.itemName)
                        .font(.headline)
                    Text(recommendation.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("$\(formatPrice(recommendation.estimatedPrice))")
                        .font(.headline)
                    Text("\(formatQuantity(recommendation.quantity)) × $\(formatPrice(recommendation.estimatedPrice))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let analysis = priceAnalysis {
                HStack {
                    Image(systemName: analysis.isGoodDeal ? "checkmark.circle.fill" : "info.circle.fill")
                        .foregroundColor(analysis.isGoodDeal ? .green : .blue)
                        .font(.caption)

                    Text(analysis.recommendation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if analysis.isGoodDeal {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("\(Int(analysis.savingsPercentage))% below average")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }

            Text("Priority: \(Int(recommendation.priority * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct SuggestionCard: View {
    let suggestion: ShoppingListRecommendation

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.itemName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(suggestion.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("$\(formatPrice(suggestion.estimatedPrice))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Helper formatting functions
private func formatPrice(_ price: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.string(from: price as NSDecimalNumber) ?? "0.00"
}

private func formatQuantity(_ quantity: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    return formatter.string(from: quantity as NSDecimalNumber) ?? "0"
}

#Preview {
    NavigationView {
        ShoppingRecommendationsView()
    }
}
