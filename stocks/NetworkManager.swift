//
//  NetworkManager.swift
//  stocks
//
//  Created by Devon Chan on 2024-08-12.
//

import Foundation

// Singleton class to manage network requests
class NetworkManager {
    // Base URL of the API
    private let baseURL = "https://ms-finance.p.rapidapi.com"
    
    // Provided API headers
    let headers = [
        "x-rapidapi-key": "d4c2a8d472msha0e601434fe2e25p15f7e2jsn0a90c8b3fdaf",
        "x-rapidapi-host": "ms-finance.p.rapidapi.com"
    ]
    
    // Singleton instance of the class
    static let shared = NetworkManager()
    private init() {}
    
    // Function to fetch stock data
    func fetchStockData(for symbol: String, completion: @escaping (Result<[Stock], Error>) -> Void) {
        // Construct the URL
        let urlString = "\(baseURL)/market/v2/auto-complete?q=\(symbol)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Ensure we received data
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            // Parse the JSON data
            do {
                let decoder = JSONDecoder()
                let responseData = try decoder.decode(StockResponse.self, from: data)
                completion(.success(responseData.results))
            } catch {
                completion(.failure(error))
            }
        }
        
        // Start the task
        task.resume()
    }
    
    // Function to fetch real-time price data using performanceId
    func fetchRealTimePrice(for performanceId: String, completion: @escaping (Result<Double, Error>) -> Void) {
        let urlString = "\(baseURL)/stock/v2/get-realtime-data?performanceId=\(performanceId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let realTimeData = try decoder.decode(RealTimeDataResponse.self, from: data)
                completion(.success(realTimeData.lastPrice))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // enum responsible for holding any error information
    enum NetworkError: Error {
        case invalidURL
        case noData
    }
}
