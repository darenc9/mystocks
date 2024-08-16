//
//  StockTableViewController.swift
//  stocks
//
//  Created by Devon Chan on 2024-08-12.
//

import UIKit
import CoreData

class StockTableViewController: UITableViewController {
    // MARK: - Initializers
    private var stockList: StockList!
    private var activeStocks: [StockEntity] = []
    private var watchStocks: [StockEntity] = []
    
    // Core Data context
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable drag interactions for the table view
        tableView.dragInteractionEnabled = true
        
        // Initialize stockList with the Core Data context
        stockList = StockList(context: context)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshStocks), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        //deleteAllRecords(for: "StockEntity", in: context)
        //deleteAllRecords(for: "StockListEntity", in: context)
        
        loadStocks()
    }

    // MARK: - Stock Management Functions
    private func loadStocks() {
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        stockList.getList(for: .active) { [weak self] result in
            switch result {
            case .success(let stocks):
                self?.activeStocks = stocks
            case .failure(let error):
                print("Failed to load active stocks: \(error.localizedDescription)")
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        stockList.getList(for: .watch) { [weak self] result in
            switch result {
            case .success(let stocks):
                self?.watchStocks = stocks
            case .failure(let error):
                print("Failed to load watch stocks: \(error.localizedDescription)")
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            // Now that we have the stocks, update their prices
            self.updateStockPrices {
                self.tableView.reloadData()
            }
        }
    }

    private func updateStockPrices(completion: @escaping () -> Void) {
        let allStocks = activeStocks + watchStocks
        let dispatchGroup = DispatchGroup()

        for stock in allStocks {
            dispatchGroup.enter()
            stockList.updateStockPrice(for: stock) {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }


    @objc private func refreshStocks() {
        loadStocks()
        tableView.refreshControl?.endRefreshing()
    }
    
    func addStock(using form: StockForm) {
        stockList.searchAndAddStocks(symbol: form.ticker, to: form.listType) { [weak self] in
            DispatchQueue.main.async {
                self?.loadStocks()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? activeStocks.count : watchStocks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Active List" : "Watch List"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StockCell", for: indexPath)
        let stock: StockEntity

        switch indexPath.section {
        case 0:
            stock = activeStocks[indexPath.row]
        case 1:
            stock = watchStocks[indexPath.row]
        default:
            fatalError("Unexpected section")
        }
        
        let ticker = stock.ticker ?? "Unknown Ticker"
        let name = stock.name ?? "Unknown Name"

        // Determine the emoji based on the stock's rank
        let rankEmoji: String
        switch stock.rank {
        case "Cold":
            rankEmoji = "❄️"
        case "Hot":
            rankEmoji = "🔥"
        case "Very Hot":
            rankEmoji = "🌋"
        default:
            rankEmoji = ""
        }

        // Combine the emoji, ticker, and name
        cell.textLabel?.text = "\(rankEmoji) \(ticker) - \(name)"
        cell.detailTextLabel?.text = String(format: "$%.2f", stock.price)
        
        return cell
    }

    // MARK: - Set Stock Rank
    func setRank(for stock: StockEntity, rank: String?) {
        stock.rank = rank // Update the rank attribute
        do {
            try context.save() // Save changes to Core Data
            print("Updated rank for \(stock.ticker ?? "Unknown"): \(rank)")
        } catch {
            print("Failed to save rank: \(error)")
        }
    }
    
    // MARK: - Handle Row Selection
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let stock: StockEntity
        let listType: StockListType

        if indexPath.section == 0 {
            stock = activeStocks[indexPath.row]
            listType = .active
        } else {
            stock = watchStocks[indexPath.row]
            listType = .watch
        }

        let alert = UIAlertController(title: "Manage Stock", message: "What would you like to do with \(stock.ticker ?? "Unknown")?", preferredStyle: .actionSheet)

        // Add option to move the stock to the other list
        let moveActionTitle = (listType == .active) ? "Move to Watch List" : "Move to Active List"
        let moveAction = UIAlertAction(title: moveActionTitle, style: .default) { [weak self] _ in
            self?.moveStock(stock, from: listType)
        }
        alert.addAction(moveAction)

        // Add options for ranking
        let rankAction = UIAlertAction(title: "Set Rank", style: .default) { [weak self] _ in
            let rankOptions = UIAlertController(title: "Set Rank", message: nil, preferredStyle: .actionSheet)
            
            // Ranking options
            let rankOptionsArray = ["None", "Cold", "Hot", "Very Hot"]
            for rank in rankOptionsArray {
                rankOptions.addAction(UIAlertAction(title: rank, style: .default) { [weak self] _ in
                    self?.setRank(for: stock, rank: rank == "None" ? nil : rank)
                    self?.tableView.reloadData() // Reload table view to reflect rank changes
                })
            }
            
            rankOptions.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self?.present(rankOptions, animated: true)
        }
        alert.addAction(rankAction)

        // Add option to delete the stock from the list
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteStock(stock, from: listType)
        }
        alert.addAction(deleteAction)

        // Add cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }




    // MARK: - Move and Delete Stock Methods

    private func moveStock(_ stock: StockEntity, from currentList: StockListType) {
        // Remove from the current list
        if currentList == .active {
            activeStocks.removeAll { $0 == stock }
            watchStocks.append(stock)
        } else {
            watchStocks.removeAll { $0 == stock }
            activeStocks.append(stock)
        }
        
        // Save the updated lists
        updateStockOrder()
        tableView.reloadData()
    }

    private func deleteStock(_ stock: StockEntity, from listType: StockListType) {
        // Remove the stock from the relevant list
        if listType == .active {
            activeStocks.removeAll { $0 == stock }
        } else {
            watchStocks.removeAll { $0 == stock }
        }
        
        // Remove from Core Data
        context.delete(stock)
        do {
            try context.save()
        } catch {
            print("Failed to delete stock: \(error)")
        }
        
        tableView.reloadData()
    }
    
    func updateStockOrder() {
        let dispatchGroup = DispatchGroup()
        
        // Update active list
        dispatchGroup.enter()
        updateStockList(for: .active, with: activeStocks) {
            dispatchGroup.leave()
        }

        // Update watch list
        dispatchGroup.enter()
        updateStockList(for: .watch, with: watchStocks) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            print("Stock orders updated successfully.")
        }
    }

    private func updateStockList(for listType: StockListType, with stocks: [StockEntity], completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<StockListEntity> = StockListEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "listType == %@", listType.rawValue)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let listEntity = results.first {
                // Convert NSOrderedSet to NSMutableOrderedSet
                let mutableStocks = listEntity.stocks?.mutableCopy() as? NSMutableOrderedSet
                
                // Remove all existing stocks
                mutableStocks?.removeAllObjects()
                
                // Add stocks in the new order
                for stock in stocks {
                    mutableStocks?.add(stock)
                }
                
                listEntity.stocks = mutableStocks
                try context.save()
            }
            completion()
        } catch {
            print("Failed to update stock order: \(error)")
            completion()
        }
    }
    
    
    // MARK: - IBActions
    
    // IBAction function to switch segue to add stock page when add button is pressed
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "AddStockSegue", sender: self)
    }
    
    // IBAction function to switch segue to Search Stock page when search button is pressed
    @IBAction func searchButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "ShowSearchStockSegue", sender: self)
    }
    
    
    // MARK: - Functions
    
/*
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
  */
    
    func deleteAllRecords(for entityName: String, in context: NSManagedObjectContext) {
        // Create a fetch request for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        // Create a batch delete request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            // Perform the batch delete request
            let batchDeleteResult = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
            print("Deleted \(batchDeleteResult?.result ?? 0) records from \(entityName)")
        } catch {
            print("Failed to delete all records: \(error)")
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "AddStockSegue" {
               if let navigationController = segue.destination as? UINavigationController,
                  let destinationVC = navigationController.topViewController as? AddStockTableViewController {
                   destinationVC.onSave = { [weak self] form in
                       self?.addStock(using: form)
                   }
               } else {
                   print("Destination view controller is not AddStockTableViewController")
               }
           }

           if segue.identifier == "SearchStockSegue" {
               if let navigationController = segue.destination as? UINavigationController,
                  let searchStockVC = navigationController.topViewController as? SearchStockTableViewController {
                   searchStockVC.stockList = self.stockList
                   searchStockVC.onUpdate = { [weak self] in
                       self?.loadStocks()
                   }
               } else {
                   print("Destination view controller is not SearchStockTableViewController")
               }
           }
       }
   }
