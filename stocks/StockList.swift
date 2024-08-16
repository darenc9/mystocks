//
//  StockList.swift
//  stocks
//
//  Created by Devon Chan on 2024-08-12.
//

import Foundation
import CoreData

// MARK: - Structs and enums

// Structures for API response and stock data
struct RealTimeDataResponse: Codable {
    let lastPrice: Double
}

// Struct to receive stock response from API
struct StockResponse: Codable {
    let count: Int
    let pages: Int
    let results: [Stock]
}

// Struct to hold stock information
struct Stock: Codable {
    let name: String
    let exchange: String
    let ticker: String
    let performanceId: String
    var price: Double? // stores obtained price value
}

// Enum for stock list types
enum StockListType: String {
    case active = "Active"
    case watch = "Watch"
}

// Struct to hold user input from completing the "Add Stock" form 
struct StockForm {
    var ticker: String
    var listType: StockListType
}

// MARK: - StockList Class
// Class responsible for controlling the StockEntity and StockEntityList entity models
// Provides useful member functions for controlling the entities 
class StockList {

    // Core Data context
    let context: NSManagedObjectContext

    // Initializer
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Add/Remove Stocks

    /// Add a stock to the specified list type.
    func addToList(_ stock: StockEntity, listType: StockListType) {
        let fetchRequest: NSFetchRequest<StockListEntity> = StockListEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "listType == %@", listType.rawValue)

        do {
            let results = try context.fetch(fetchRequest)
            if let listEntity = results.first {
                let mutableStocks = listEntity.stocks?.mutableCopy() as? NSMutableOrderedSet
                mutableStocks?.add(stock)
                listEntity.stocks = mutableStocks
                try context.save()
            } else {
                let newList = StockListEntity(context: context)
                newList.listType = listType.rawValue
                let mutableStocks = NSMutableOrderedSet()
                mutableStocks.add(stock)
                newList.stocks = mutableStocks
                try context.save()
            }
        } catch {
            print("Failed to fetch or save stock: \(error)")
        }
    }

    // Remove a stock from a specified list type
    func removeFromList(_ stock: StockEntity, listType: StockListType) {
        let fetchRequest: NSFetchRequest<StockListEntity> = StockListEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "listType == %@", listType.rawValue)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let listEntity = results.first {
                // Convert NSOrderedSet to an array for comparison
                if let stocks = listEntity.stocks?.array as? [StockEntity] {
                    // Find the stock to remove by comparing ticker symbols
                    if let stockToRemove = stocks.first(where: { $0.ticker == stock.ticker }) {
                        listEntity.removeFromStocks(stockToRemove)
                        try context.save()
                    }
                }
            }
        } catch {
            print("Failed to fetch or delete stock: \(error)")
        }
    }

    // MARK: - Move Stocks

    /// Move a stock from one list to another.
    func moveStock(_ stock: StockEntity, from oldListType: StockListType, to newListType: StockListType) {
        removeFromList(stock, listType: oldListType)
        addToList(stock, listType: newListType)
    }

    // MARK: - Count and Fetch Stocks

    /// Returns the number of stocks in the specified list type.
    func count(for listType: StockListType) -> Int {
        let fetchRequest: NSFetchRequest<StockListEntity> = StockListEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "listType == %@", listType.rawValue)

        do {
            let results = try context.fetch(fetchRequest)
            if let listEntity = results.first {
                return listEntity.stocks?.count ?? 0
            } else {
                return 0
            }
        } catch {
            print("Failed to count stocks: \(error)")
            return 0
        }
    }
    

    // MARK: - Fetch Stocks

    /// Get the list of stocks for a specified list type.
    func getList(for listType: StockListType, completion: @escaping (Result<[StockEntity], Error>) -> Void) {
        let fetchRequest: NSFetchRequest<StockListEntity> = StockListEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "listType == %@", listType.rawValue)

        do {
            let results = try context.fetch(fetchRequest)
            if let listEntity = results.first {
                if let stocks = listEntity.stocks {
                    completion(.success(stocks.array as! [StockEntity]))
                } else {
                    completion(.success([]))
                }
            } else {
                completion(.success([]))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Search for stocks based on a symbol in Core Data.
    func searchStocks(for symbol: String, completion: @escaping (Result<[StockEntity], Error>) -> Void) {
        let fetchRequest: NSFetchRequest<StockEntity> = StockEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ticker == %@", symbol)

        do {
            let results = try context.fetch(fetchRequest)
            completion(.success(results))
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Check if a stock with the given ticker symbol is in the specified list type.
    func isStockInList(withTicker ticker: String, listType: StockListType, completion: @escaping (Bool) -> Void) {
        getList(for: listType) { result in
            switch result {
            case .success(let stocks):
                let isInList = stocks.contains(where: { $0.ticker == ticker })
                completion(isInList)
            case .failure(let error):
                print("Failed to fetch list: \(error.localizedDescription)")
                completion(false)
            }
        }
    }


    // MARK: - Search and Add

    /// Search for a stock and add it to the list. If not found, fetch from API and save.
    func searchAndAddStocks(symbol: String, to listType: StockListType, completion: @escaping () -> Void) {
        searchStocks(for: symbol) { [weak self] result in
            switch result {
            case .success(let stocks):
                DispatchQueue.main.async {
                    if let firstStock = stocks.first {
                        self?.addToList(firstStock, listType: listType)
                        self?.updateStockPrice(for: firstStock) {
                            completion()
                        }
                    } else {
                        self?.fetchAndSaveStockFromAPI(symbol: symbol, listType: listType, completion: completion)
                    }
                }
            case .failure(let error):
                print("Failed to search stocks: \(error)")
                completion()
            }
        }
    }

    // MARK: - Create and Update

    /// Create a StockEntity from a Stock (API model).
    func createStockEntity(from stock: Stock) -> StockEntity {
        let stockEntity = StockEntity(context: context)
        stockEntity.name = stock.name
        stockEntity.ticker = stock.ticker
        stockEntity.performanceId = stock.performanceId
        stockEntity.price = stock.price ?? 0.0
        return stockEntity
    }

    /// Update the price of a stock.
    func updateStockPrice(for stock: StockEntity, completion: @escaping () -> Void) {
        guard let performanceId = stock.performanceId else {
            completion()
            return
        }

        NetworkManager.shared.fetchRealTimePrice(for: performanceId) { [weak self] result in
            switch result {
            case .success(let price):
                DispatchQueue.main.async {
                    stock.price = price
                    do {
                        try self?.context.save()
                        print("Updated price for \(stock.ticker ?? "Unknown"): \(price)")
                    } catch {
                        print("Failed to save updated price: \(error)")
                    }
                    completion()
                }
            case .failure(let error):
                print("Failed to fetch real-time price: \(error)")
                completion()
            }
        }
    }

    func setRank(for stock: StockEntity, rank: String?) {
    // Update the rank for the stock
    stock.rank = rank
    do {
        try context.save()
    } catch {
        print("Failed to save rank: \(error)")
    }
    }

    // MARK: - Private API Fetching

    /// Fetch and save stock from API.
    private func fetchAndSaveStockFromAPI(symbol: String, listType: StockListType, completion: @escaping () -> Void) {
        NetworkManager.shared.fetchStockData(for: symbol) { [weak self] result in
            switch result {
            case .success(let stocks):
                DispatchQueue.main.async {
                    if let firstStock = stocks.first {
                        let stockEntity = self?.createStockEntity(from: firstStock)
                        if let stockEntity = stockEntity {
                            self?.addToList(stockEntity, listType: listType)
                            self?.updateStockPrice(for: stockEntity) {
                                // Notify the completion of the update process
                                completion()
                            }
                        }
                    } else {
                        print("No stocks found to add from API.")
                        completion()
                    }
                }
            case .failure(let error):
                print("Failed to fetch stock from API: \(error)")
                completion()
            }
        }
    }

}




