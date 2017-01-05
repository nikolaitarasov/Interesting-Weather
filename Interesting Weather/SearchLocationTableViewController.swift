//
//  SearchLocationTableViewController.swift
//  Interesting Weather
//
//  Created by Mykola Tarasov on 10/29/16.
//  Copyright © 2016 Nikolai Tarasov. All rights reserved.
//

import UIKit

class SearchLocationTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchField: UITextField!
    
    var listOfAllLocations = [String]()
    var listOfSuggestedLocations = [String]()
    var listOfQueryStrings = [String]()
    var listOfRecentSearches = [String]()
    var recentSearchCoordinates = [Double]()
    var suggestedLocations = [String: String]()
    var numberOfSections = 1

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.searchField.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ?
            self.listOfRecentSearches.count + 1 : self.listOfSuggestedLocations.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView
            .dequeueReusableCell(withIdentifier: "cell", for:indexPath) as UITableViewCell
        
        cell.detailTextLabel?.text = ""
        
        if (indexPath.section == 0) {
            
            // set current location
            if indexPath.row == 0 {
                
                cell.textLabel?.text = "Current Location"
                cell.textLabel?.textColor = UIColor.orange
                
                let currentLocationName = UserDefaults.standard
                                            .value(forKey: "currentLocation") as? String
                cell.detailTextLabel?.text = currentLocationName
            }
            
            if !listOfRecentSearches.isEmpty {
                let index = indexPath.row as Int
                cell.textLabel?.text = self.listOfRecentSearches[index]
            }
        } else if (indexPath.section == 1) {
            let index = indexPath.row as Int
            cell.textLabel?.text = self.listOfSuggestedLocations[index]
        }
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var queryString: String
        var latitude: Double
        var longitude: Double
        
        let mainTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "MainTableViewController") as? MainTableViewController
        
        self.navigationController?.pushViewController(mainTableViewController!, animated: true)
        
        if indexPath.section == 0 {
            
            // set current location
            if indexPath.row == 0 {
                let currentLocationCoordinates = UserDefaults.standard
                    .value(forKey: "currentLocationCoordinates") as! [Double] // TO DO
                latitude = currentLocationCoordinates[0]
                longitude = currentLocationCoordinates[1]
                
                mainTableViewController!.showForecastAtCurrentLocation = true
            } else {
                latitude = self.recentSearchCoordinates[0]
                longitude = self.recentSearchCoordinates[1]
            }

            queryString = "/q/\(latitude),\(longitude)" as String
        } else {
            let selectedCell = tableView.cellForRow(at: indexPath)
            
            queryString = self.suggestedLocations[(selectedCell?.textLabel?.text)!]!
            
            mainTableViewController!.showForecastAtCurrentLocation = false
        }
        
        mainTableViewController!.getWeatherData("http://api.wunderground.com/api/039c218d32896214/forecast/geolookup/conditions\(queryString).json")
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "RECENT SEARCHES" : "SEARCH RESULTS"
    }
    
    
    // MARK - UITextFieldDelegate
    

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.isEmpty {
            self.numberOfSections = 1
            self.tableView.reloadData()
        } else {
            let substring = (self.searchField.text! as NSString)
                .replacingCharacters(in: range, with: string)
            
            searchAutocompleteEntriesWithSubstring(substring)
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    
    // MARK - Private methods
    
    
    func getSuggestData (_ urlString: String) {
        let url = URL(string: urlString)
        let task = URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            DispatchQueue.main.async(execute: {
                self.getListOfSuggestedCities(data!)
            })
        })
        task.resume()
    }
    
    
    func getListOfSuggestedCities(_ suggestData: Data) {
        self.listOfAllLocations.removeAll()
        self.listOfQueryStrings.removeAll()
        
        do {
            let json = try JSONSerialization
                .jsonObject(with: suggestData, options:.allowFragments) as! NSDictionary
            if let results = json["RESULTS"] as? [[String: AnyObject]] {
                for result in results {
                    if let locationName = result["name"] as? String {
                        self.listOfAllLocations.append(locationName)
                    }
                    if let queryString = result["l"] as? String {
                        self.listOfQueryStrings.append(queryString)
                    }
                    
                    let locationName = result["name"] as? String
                    let queryString = result["l"] as? String
                    self.suggestedLocations[locationName!] = queryString
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func searchAutocompleteEntriesWithSubstring(_ substring: String) {
        
        self.listOfSuggestedLocations.removeAll()
        
        var newSubstring = substring
        newSubstring = newSubstring.replacingOccurrences(of: " ", with: "%20")
        getSuggestData("http://autocomplete.wunderground.com/aq?query=\(newSubstring)")
        
        for location in listOfAllLocations {
            
            let isLowercased: Bool = substring.lowercased() == substring
            
            var suggestedCityName:NSString
                
            if isLowercased == true {
                suggestedCityName = location.lowercased() as NSString!
            } else {
                suggestedCityName = location as NSString!
            }
            
            let substringRange:NSRange! = suggestedCityName.range(of: substring)
            if (substringRange.location == 0) {
                self.listOfSuggestedLocations.append(location)
            }
        }
        
        self.numberOfSections = 2
        
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }

    @IBOutlet weak var editRecentSearchesAction: UIBarButtonItem!

}
