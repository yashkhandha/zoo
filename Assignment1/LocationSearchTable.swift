//
//  LocationSearchTable.swift
//  Assignment1
//
//  Created by Yash Khandha on 3/9/18.
//  Copyright © 2018 Yash Khandha. All rights reserved.
//

/// Importing UIKit to handle event driven user interface
import UIKit
/// Importing Mapkit to access map and its functions
import MapKit

/// This class handles the location to be shown in cell view when user enters address
/// Tutorial referred for implementing this feature. Reference -> https://www.thorntech.com
class LocationSearchTable : UITableViewController {
    
    var matchingItems:[MKMapItem] = []
    var mapView: MKMapView? = nil
    
    //to handle pin drop
    var handleMapSearchDelegate:HandleMapSearch? = nil
    
    func parseAddress(selectedItem:MKPlacemark) -> String {
        // put a space
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between city and state
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
}

// MARK: - Updating the search result on entering address
extension LocationSearchTable : UISearchResultsUpdating {
    
    /// This function handles the updating search results using UISearchController
    ///
    /// - Parameter searchController: to search through the searchbar
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
            let searchBarText = searchController.searchBar.text else { return }
        /// Using the MKLocalSearchRequest() to fetch all the locations and their address
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}

// MARK: - Table operations
extension LocationSearchTable {
    /// Returns the count of search results
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - section: item selected index
    /// - Returns: number of rows in selected section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    /// to displaye the cell values
    ///
    /// - Parameters:
    ///   - tableView: view
    ///   - indexPath: index of selected row
    /// - Returns: cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let selectedItem = matchingItems[indexPath.row].placemark
        /// set the cell value to selected item
        cell.textLabel?.text = selectedItem.name
        /// calls the parseAddress method to handle the formatting of the location selected
        cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
    
    /// To handle the selection of row in section
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index of row selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        handleMapSearchDelegate?.dropPinZoomIn(placemark: selectedItem)
        dismiss(animated: true, completion: nil)
    }
}

