//
//  AddStockTableViewController.swift
//  stocks
//
//  Created by Devon Chan on 2024-08-12.
//

import UIKit

// This controller is responsible for adding a new stock to either the active list or watch list
class AddStockTableViewController: UITableViewController {
    
    // MARK: - Outlet & Initializer
    
    @IBOutlet weak var tickerTextField: UITextField! // TextField to enter stock ticker
    @IBOutlet weak var listSegmentedControl: UISegmentedControl! // To select list type
    
    var onSave: ((StockForm) -> Void)? // Closure to handle saving the stock form data
    
    // Called after the controller's view has been loaded into memory
    override func viewDidLoad() {
        super.viewDidLoad()
        // Sets default selected list to active list
        listSegmentedControl.selectedSegmentIndex = 0
    }

    // MARK: - Table view data source

    /// Returns the number of sections in the table view
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    /// Returns the number of rows in each section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    // MARK: - IBAction Functions
    
    // Button action for the "save" navbar button
    @IBAction func saveButtonTapped(_ sender: Any) {
        // Safety check, ensures a ticker symbol was inputted
        guard let ticker = tickerTextField.text, !ticker.isEmpty else {
            // Show an alert if ticker is empty
            let alert = UIAlertController(title: "Error", message: "Please enter a ticker symbol.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        // Determines selected list type
        let listType: StockListType = listSegmentedControl.selectedSegmentIndex == 0 ? .active : .watch
        let form = StockForm(ticker: ticker, listType: listType)
        // Call the onSave closure with the form data
        onSave?(form)
        dismiss(animated: true, completion: nil)
    }
    
    // Button action for the "cancel" navbar button
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}
