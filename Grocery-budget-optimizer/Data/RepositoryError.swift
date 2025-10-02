//
//  RepositoryError.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation

enum RepositoryError: Error, LocalizedError {
    case notFound
    case invalidData
    case saveFailed
    case fetchFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Item not found"
        case .invalidData:
            return "Invalid data provided"
        case .saveFailed:
            return "Failed to save data"
        case .fetchFailed:
            return "Failed to fetch data"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}