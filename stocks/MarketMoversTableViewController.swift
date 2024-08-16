//
//  MarketMoversTableViewController.swift
//  stocks
//
//  Created by Devon Chan on 2024-08-14.
//

import UIKit

// This TableViewController class is for the Market Movers page to display active stocks  that are gaining or losing
class MarketMoversTableViewController: UITableViewController {
    //MARK: - Declarations & Initializers
    
    // Array of Movers to hold active, gainer, and loser mover stocks
    var actives: [Mover] = []
    var gainers: [Mover] = []
    var losers: [Mover] = []

    // Override viewDidLoad() to initialize view
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // URL of the API endpoint
        let urlString = "https://ms-finance.p.rapidapi.com/market/v2/get-movers"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Fetch market movers data
        fetchMarketMovers(from: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let marketMoversResponse):
                    // Update properties with fetched data
                    self.actives = marketMoversResponse.actives
                    self.gainers = marketMoversResponse.gainers
                    self.losers = marketMoversResponse.losers
                    
                    // Reload UI elements, e.g., table view or collection view
                    self.tableView.reloadData()
                    
                case .failure(let error):
                    // Handle error
                    print("Failed to fetch market movers: \(error.localizedDescription)")
                    
                    // Show an error message to the user or handle it accordingly
                }
            }
        }
    }
    // MARK: - Table view data source

    // To configure the table view, we return the number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    // To configure the table view, we return the number of rows per section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return actives.count
        case 1:
            return gainers.count
        case 2:
            return losers.count
        default:
            return 0
        }
    }
    
    // To configure the table view, we return the title for each section
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Actives"
        case 1:
            return "Gainers"
        case 2:
            return "Losers"
        default:
            return nil
        }
    }

    // Configures the cell for each row with the Market Mover Stocks information
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MarketMoverCell", for: indexPath)

        let mover: Mover
        switch indexPath.section {
        case 0:
            mover = actives[indexPath.row]
        case 1:
            mover = gainers[indexPath.row]
        case 2:
            mover = losers[indexPath.row]
        default:
            fatalError("Unexpected section")
        }

        // Create a NumberFormatter instance
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = "$"
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2

        // Format lastPrice
        let formattedPrice = numberFormatter.string(from: NSNumber(value: mover.lastPrice)) ?? "\(mover.lastPrice)"

        // Configure the cell
        cell.textLabel?.text = mover.name
        cell.detailTextLabel?.text = "\(mover.ticker) - \(formattedPrice) (\(String(format: "%.2f", mover.netChange)))%"

        return cell
    }


    // MARK: - IBAction Functions
    
    ///IBAction for the done button. Dismisses this page when pressed.
    @IBAction func doneButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
