//
//  SearchStockTableViewCell.swift
//  stocks
//
//  Created by Devon Chan on 2024-08-13.
//

import Foundation
import UIKit

// Custom UITableViewCell for displaying stock information in a search result
class SearchStockTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameTickerLabel: UILabel! // Label to display stock name and ticker
    @IBOutlet weak var priceLabel: UILabel! // Label to display stock's current price
    @IBOutlet weak var listSegmentedControl: UISegmentedControl! // Control to select list
    
    // Initializer for creating the cell programmatically
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    // Initializer for creating the cell from a storyboard or nib file
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    // Method to perform any additional setup for the cell's views
    private func setupView() {
        // Additional setup if needed
    }
}
