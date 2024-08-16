//
//  SearchStockTableViewController.swift
//  stocks
//
//  Created by Devon Chan on 2024-08-13.
//

import UIKit

// This controller is responsible for the app's search page
class SearchStockTableViewController: UITableViewController, UISearchBarDelegate {

    // MARK: - Outlets & Initializers

    var filteredStocks: [Stock] = [] // Array to store search results
    var stockList: StockList? // reference to the main stock list
    var onUpdate: (() -> Void)?
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Called when view loads
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up search bar delegate
        searchBar.delegate = self
    }

    // MARK: - Table view data source

    /// Returns the number of sections for the Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    /// Returns the number of rows for the Table View
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredStocks.count
    }

    ///  Configures the cell for each row at the index path
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchStockCell", for: indexPath) as? SearchStockTableViewCell else {
            fatalError("Failed to dequeue a SearchStockCell.")
        }
        
        let stock = filteredStocks[indexPath.row]
        cell.nameTickerLabel.text = "\(stock.name) (\(stock.ticker))"
        
        // Initially show "Loading..." until price is fetched
        cell.priceLabel.text = "Loading..."
        
        // Fetch real-time price using the performanceId
        NetworkManager.shared.fetchRealTimePrice(for: stock.performanceId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let price):
                    cell.priceLabel.text = "$\(String(format: "%.2f", price))"
                case .failure(let error):
                    print("Failed to fetch price: \(error.localizedDescription)")
                    cell.priceLabel.text = "N/A"
                }
            }
        }

        // Set the segmented control based on the stock's presence in the lists
        if let stockList = stockList {
            stockList.getList(for: .active) { result in
                switch result {
                case .success(let activeStocks):
                    stockList.getList(for: .watch) { result in
                        switch result {
                        case .success(let watchStocks):
                            DispatchQueue.main.async {
                                if activeStocks.contains(where: { $0.ticker == stock.ticker }) {
                                    cell.listSegmentedControl.selectedSegmentIndex = 1 // Active
                                } else if watchStocks.contains(where: { $0.ticker == stock.ticker }) {
                                    cell.listSegmentedControl.selectedSegmentIndex = 2 // Watch
                                } else {
                                    cell.listSegmentedControl.selectedSegmentIndex = 0 // None
                                }
                            }
                        case .failure(let error):
                            print("Failed to fetch watch stocks: \(error.localizedDescription)")
                            cell.listSegmentedControl.selectedSegmentIndex = 0
                        }
                    }
                case .failure(let error):
                    print("Failed to fetch active stocks: \(error.localizedDescription)")
                    cell.listSegmentedControl.selectedSegmentIndex = 0
                }
            }
        } else {
            // Handle the case where stockList is nil (though it shouldn't be)
            cell.listSegmentedControl.selectedSegmentIndex = 0 // None
        }
        
        cell.listSegmentedControl.tag = indexPath.row
        cell.listSegmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        return cell
    }


    // Override function to control what happens after view disappears
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Call the onUpdate closure when the view controller is dismissed
        onUpdate?()
    }
    
    // MARK: - Actions
    
    // Called when the segmented control's value is changed
    @objc func segmentChanged(_ sender: UISegmentedControl) {
        let stock = filteredStocks[sender.tag]
        let selectedIndex = sender.selectedSegmentIndex
        
        // Check if the stock is in any list
        checkStockLists(for: stock) { [weak self] isInActiveList, isInWatchList in
            // Fetch real-time price
            self?.fetchAndUpdatePrice(for: stock) { [weak self] price in
                guard let price = price else { return }
                
                // Create the StockEntity from the updated stock
                guard let stockEntity = self?.createStockEntity(from: stock) else {
                    print("Failed to create StockEntity from stock")
                    return
                }
                
                // Update the stock lists based on the selected segment index
                switch selectedIndex {
                case 1: // Active
                    if isInWatchList {
                        // Move from Watch to Active
                        self?.stockList?.moveStock(stockEntity, from: .watch, to: .active)
                        print("\(stock.ticker) moved from watch list to active list")
                    } else if !isInActiveList {
                        // Add to Active
                        self?.stockList?.addToList(stockEntity, listType: .active)
                        print("\(stock.ticker) added to active list")
                    }
                    
                case 2: // Watch
                    if isInActiveList {
                        // Move from Active to Watch
                        self?.stockList?.moveStock(stockEntity, from: .active, to: .watch)
                        print("\(stock.ticker) moved from active list to watch list")
                    } else if !isInWatchList {
                        // Add to Watch
                        self?.stockList?.addToList(stockEntity, listType: .watch)
                        print("\(stock.ticker) added to watch list")
                    }
                    
                default: // None
                    if isInActiveList {
                        // Remove from Active
                        self?.stockList?.removeFromList(stockEntity, listType: .active)
                        print("\(stock.ticker) removed from active list")
                    }
                    if isInWatchList {
                        // Remove from Watch
                        self?.stockList?.removeFromList(stockEntity, listType: .watch)
                        print("\(stock.ticker) removed from watch list")
                    }
                }
                
                // Optionally, reload the table view or update UI to reflect changes
                self?.tableView.reloadData()
            }
        }
    }
    
    // Action to control the done button, which returns user to the stock list by dismissing this page
    @IBAction func doneButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helper Functions

    // Function used to create a StockEntity from a Stock
    func createStockEntity(from stock: Stock) -> StockEntity {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let stockEntity = StockEntity(context: context)
        stockEntity.name = stock.name
        stockEntity.ticker = stock.ticker
        stockEntity.performanceId = stock.performanceId
        stockEntity.price = stock.price ?? 0.0
        return stockEntity
    }
    
    // Function accepts a stock as the parameter, and checks if the stock is in the user's stock list
    private func checkStockLists(for stock: Stock, completion: @escaping (Bool, Bool) -> Void) {
        let group = DispatchGroup()
        var isInActiveList = false
        var isInWatchList = false
        
        group.enter()
        stockList?.isStockInList(withTicker: stock.ticker, listType: .active) { isInList in
            isInActiveList = isInList
            group.leave()
        }
        
        group.enter()
        stockList?.isStockInList(withTicker: stock.ticker, listType: .watch) { isInList in
            isInWatchList = isInList
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(isInActiveList, isInWatchList)
        }
    }

    // Function used to fetch the current price of a particular stock
    private func fetchAndUpdatePrice(for stock: Stock, completion: @escaping (Double?) -> Void) {
        NetworkManager.shared.fetchRealTimePrice(for: stock.performanceId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let price):
                    completion(price)
                case .failure(let error):
                    print("Failed to fetch price: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }


    

    // MARK: - UISearchBarDelegate
    
    /// Called when the search button is clicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // Dismiss the keyboard
        
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            // If search text is empty, clear the filtered stocks
            filteredStocks = []
            tableView.reloadData()
            return
        }
        
        // Fetch stock data using the NetworkManager
        NetworkManager.shared.fetchStockData(for: searchText) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stocks):
                    self?.filteredStocks = stocks
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("Failed to fetch stock data: \(error.localizedDescription)")
                    self?.filteredStocks = []
                    self?.tableView.reloadData()
                }
            }
        }
    }

}

