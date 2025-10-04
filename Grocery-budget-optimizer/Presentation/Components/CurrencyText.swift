//
//  CurrencyText.swift
//  Grocery-budget-optimizer
//
//  Created by AI on 04/10/2025.
//

import SwiftUI

/// A SwiftUI Text component that displays a currency value with the current app currency symbol
struct CurrencyText: View {
    let value: Decimal
    @ObservedObject private var currencyManager: CurrencyManager = .shared
    
    init(value: Decimal) {
        self.value = value
    }
    
    var body: some View {
        let formattedValue = String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
        return Text("\(currencyManager.currentCurrency.symbol)\(formattedValue)")
    }
}

// Preview provider
#Preview {
    VStack(spacing: 20) {
        CurrencyText(value: 100.50)
        CurrencyText(value: 1234.99)
        CurrencyText(value: 0.99)
    }
    .padding()
}
