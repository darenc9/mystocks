//
//  StockEntity.swift
//  stocks
//
//  Created by Devon Chan on 2024-08-13.
//
//

import Foundation
import SwiftData

// Core Data model class representing a stock entity in the app.
@Model public class StockEntity {
    // Properties representing a stock's properties
    var name: String?
    var exchange: String?
    var ticker: String?
    var performanceId: String?
    var price: Double? = 0.0

    // Initializer to create a StockEntity instance
    public init() {
        // No additional setup required
    }
    
}
