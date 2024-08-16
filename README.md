# About MyStocks
`MyStocks` is an iOS app designed for stock tracking and management. With a user-friendly interface, it provides real-time data on stock performance, along with features for organizing stocks into personalized lists, setting rankings, and viewing market movers.

# Features

1. **Stock Management**
   - Add stocks to your Active or Watch List by searching for the stock and using the `add` button.
   - Flexible list management: Move stocks between the Active and Watch List by interacting with them from the `My Stocks` screen or the `Search` page.

2. **API Integration**
   - Integrated with **RapidAPI: MS Finance** to pull real-time stock information, including stock prices, volume, and performance data.

3. **Search and Discovery**
   - Use the search button to find stocks by name or ticker symbol.
   - Easily add stocks to your list via segmented control for quick selection between the Active and Watch lists.

4. **Data Persistence**
   - The app uses **Core Data** to save user data and preferences.
   - Two Core Data entities, `StockEntity` and `StockListEntity`, ensure that your stock lists and preferences persist across sessions.

5. **Stock Ranking**
   - Assign ranks to stocks as `Cold`, `Hot`, or `Very Hot`.
   - To rank a stock, click on the stock in your list, select "Set Rank," and choose the appropriate ranking.
   - Stocks with rankings are marked with visual cues, making it easy to identify their status at a glance.

6. **Real-Time Data Refresh**
   - Keep your stock data current by pulling down on the screen to refresh the information and stock prices instantly.

7. **Market Movers Page**
   - Get real-time data on the most active stocks, the biggest gainers, and the biggest losers in the market:
     - **Actives:** Stocks with the highest trading volumes.
     - **Gainers:** Stocks with the highest percentage increase in price.
     - **Losers:** Stocks with the highest percentage decrease in price.

# How to Use MyStocks

1. **Launching the App:**
   - Open the `MyStocks` app on your iOS device. You'll be greeted by the main dashboard showing your Active and Watch Lists.

2. **Adding Stocks:**
   - Tap the `+` button to add stocks to your lists.
   - You can search for stocks by name or ticker symbol in the search bar.
   - Use the Segmented Control to toggle between adding stocks to the `Active List` or the `Watch List`.

3. **Ranking Stocks:**
   - Select a stock from your list and click the `Set Rank` button.
   - Choose from `None`, `Cold`, `Hot`, or `Very Hot`. This will apply a visual cue (icon) to help you identify the rank of each stock.

4. **Moving Stocks Between Lists:**
   - Select a stock in the `My Stocks` screen and click `Move` to switch it between the Active and Watch Lists.
   - Alternatively, you can switch its list directly from the `Search` page by toggling the Segmented Control.

5. **Market Movers Page:**
   - View real-time market data for the top `Actives`, `Gainers`, and `Losers` stocks.
   - Simply swipe through the different categories to explore the most active stocks, biggest gainers, and biggest losers in the market.

6. **Refreshing Stock Data:**
   - Pull down on the screen to refresh the stock data and get the latest market updates.


# Installation
- Clone the repository:
```
git clone https://github.com/darenc9/mystocks.git
```
- Open the project in xcode
- Set up your RapidAPI credentials in the "NetworkManager.swift" file
- Build and run the app on your iOS device or simulator


# Technologies Used
- **iOS Development:** Swift, UIKit
- **Data Persistence:** Core Data
- **API Integration:** RapidAPI (MS Finance API)
- **Networking:** URLSession for API calls
- **Design Pattern:** MVC (Model-View-Controller)
