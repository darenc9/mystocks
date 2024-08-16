//
//  MarketMover.swift
//  stocks
//
//  Created by Devon Chan on 2024-08-14.
//

import Foundation
import UIKit

/**
 This is for the new feature: Market Movers
 This file contains structs to handle storing market mover stocks (stocks that are active, gaining, or losing),
 as well as fetching hot market mover stocks real-time
 */

// Define the structure for each mover stock item
struct Mover: Decodable {
    let exchange: String
    let lastPrice: Double
    let netChange: Double
    let performanceID: String
    let name: String
    let ticker: String
    let volume: Int
    let percentNetChange: Double // Updated to match JSON
}

// Define the structure for the market movers response
struct MarketMoversResponse: Decodable {
    let actives: [Mover]
    let gainers: [Mover]
    let losers: [Mover]
}

// Function to fetch market movers data
func fetchMarketMovers(from url: URL, completion: @escaping (Result<MarketMoversResponse, Error>) -> Void) {
    // Create a URLRequest object with the URL
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    // Add headers to the request
    request.addValue("ms-finance.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
    request.addValue("d4c2a8d472msha0e601434fe2e25p15f7e2jsn0a90c8b3fdaf", forHTTPHeaderField: "x-rapidapi-key")
    
    // Create a URLSession data task
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        // Handle network errors
        if let error = error {
            completion(.failure(error))
            return
        }
        
        // Check for valid response and data
        guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200 else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response or data"])
            completion(.failure(error))
            return
        }
        
        // Decode the JSON response into the MarketMoversResponse object
        do {
            let marketMoversResponse = try JSONDecoder().decode(MarketMoversResponse.self, from: data)
            completion(.success(marketMoversResponse))
        } catch {
            completion(.failure(error))
        }
    }
    
    // Start the task
    task.resume()
}
