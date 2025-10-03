//
//  Decimal+Extensions.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }

    func formatted(as currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }
    
    /// Rounds the decimal to the specified number of places
    func rounded(to places: Int) -> Decimal {
        let multiplier = NSDecimalNumber(decimal: Decimal(pow(10.0, Double(places))))
        let result = NSDecimalNumber(decimal: self).multiplying(by: multiplier)
        let rounded = NSDecimalNumber(decimal: Decimal(result.doubleValue.rounded()))
        return rounded.dividing(by: multiplier).decimalValue
    }
}