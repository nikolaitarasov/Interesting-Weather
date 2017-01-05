//
//  MainTableViewController.swift
//  Interesting Weather
//
//  Created by Mykola Tarasov on 10/18/16.
//  Copyright © 2016 Nikolai Tarasov. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MainTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var observLocationLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconTitleLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var windDirLabel: UILabel!
    @IBOutlet weak var gustsLabel: UILabel!
    @IBOutlet weak var windForceLabel: UILabel!
    @IBOutlet weak var observEffectDescription: UILabel!
    @IBOutlet weak var highTempLabel: UILabel!
    @IBOutlet weak var lowTempLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var precipitationLabel: UILabel!
    
    
    var forecastWeekdays = [String]()
    var weekdaysIcons = [String]()
    let numberOfForecastDays = 3
    
    var locationManager: CLLocationManager!
    var showForecastAtCurrentLocation = true
    var currentLocationName: String!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
      
        // implement CLLocationManager
        if self.showForecastAtCurrentLocation {
            self.locationManager = CLLocationManager()
            self.locationManager.delegate = self
            self.locationManager.distanceFilter = kCLDistanceFilterNone
            self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            self.locationManager.requestWhenInUseAuthorization()
            
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // table view
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? self.numberOfForecastDays : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView
            .dequeueReusableCell(withIdentifier: "Cell", for:indexPath) as UITableViewCell
        
        if (indexPath.section == 0) {
            
            // fill weekdays
            if self.forecastWeekdays.count > 0 {
                cell.textLabel?.text = self.forecastWeekdays[indexPath.row]
            }
            
            // fill weekdays weather icons
            if self.weekdaysIcons.count > 0 {
                let url = URL(string: self.weekdaysIcons[indexPath.row])
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!)
                    if (data != nil) {
                        DispatchQueue.main.async {
                            cell.imageView?.image = UIImage(data: data!)
                        }
                    }
                    tableView.reloadData()
                }
            }
        } else if (indexPath.section == 1) {
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "3-days Forecast" : "News"
    }

    
    // get weather data
    func getWeatherData (_ urlString: String) {
        let url = URL(string: urlString)
        let task = URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            
            DispatchQueue.main.async(execute: {
                self.setLabels(data!)
            })
        })
        task.resume()
    }
    
    
    func setLabels (_ weatherData: Data) {
        do {
            let json = try JSONSerialization
                .jsonObject(with: weatherData, options:.allowFragments) as! NSDictionary
        
            if let currentObservation = json["current_observation"] as? NSDictionary {
                setCurrentObservationLabels (currentObservation: currentObservation)
            }
            
            if let forecast = json["forecast"] as? [String: Any]  {
                if let simpleforecast = forecast["simpleforecast"] as? [String: Any]  {
                    if let forecastDaysArray = simpleforecast["forecastday"] as? [Any] {
                        
                        // today's forecast
                        let forecastToday = forecastDaysArray[0] as! [String : Any]
                        if let highTemp = forecastToday["high"] as? [String: Any] {
                            if let highTempF = highTemp["fahrenheit"] as? String {
                                self.highTempLabel.text! = highTempF + "°"
                            }
                        }
                        
                        if let lowTemp = forecastToday["low"] as? [String: Any] {
                            if let lowTempF = lowTemp["fahrenheit"] as? String {
                                self.lowTempLabel.text! = lowTempF + "°"
                            }
                        }
                        
                        // Forecast
                        for index in 1...self.numberOfForecastDays {
                            let forecast = forecastDaysArray[index] as! [String : Any]
                            if let date = forecast["date"] as? [String: Any] {
                                if let weekday = date["weekday"] as? String {
                                    self.forecastWeekdays.append(weekday)
                                }
                            }
                            if let icon = forecast["icon_url"] as? String {
                                self.weekdaysIcons.append(icon)
                            }
                            
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    // MARK - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation:CLLocation = locations[0] as CLLocation
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        // save current location coordinates to user defaults
        let coordinates = [latitude, longitude]
        UserDefaults.standard.set(coordinates, forKey: "currentLocationCoordinates")
        
        // show weather at user's current location
        getWeatherData("http://api.wunderground.com/api/039c218d32896214/forecast/geolookup/conditions/q/\(latitude),\(longitude).json")
        
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("\(error)")
    }

    
    // Private methods
    
    @IBAction func showForecastAtCurrentLocation(_ sender: Any) {
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startUpdatingLocation()
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func setCurrentObservationLabels (currentObservation: NSDictionary) {
        
        if let displayLocation = currentObservation["display_location"] as? NSDictionary {
            if let location = displayLocation["full"] as? String {
                self.locationLabel.text! = location
                
                if self.showForecastAtCurrentLocation == true {
                    UserDefaults.standard.set(self.locationLabel.text!, forKey: "currentLocation")
                }
            }
        }
        
        if let observation_location = currentObservation["observation_location"] as? NSDictionary {
            if let location = observation_location["city"] as? String {
                self.observLocationLabel.text! = location
            }
        }
        
        if let temp = currentObservation["temp_f"] as? Int {
            self.tempLabel.text! = String(temp)
            //WeatherForecastData(data)
        }
        
        if let iconUrl = currentObservation["icon_url"] as? String {
            let url = URL(string: iconUrl)
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: url!)
                if (data != nil) {
                    DispatchQueue.main.async {
                        self.iconImageView.image = UIImage(data: data!)
                    }
                }
            }
        }
        
        if let iconTitle = currentObservation["weather"] as? String {
            self.iconTitleLabel.text! = iconTitle
        }
        
        if let humidity = currentObservation["relative_humidity"] as? String {
            self.humidityLabel.text! = humidity
        }
        
        if let windSpeed = currentObservation["wind_mph"] as? Float {
            self.windLabel.text! = String(windSpeed) + " mph"
            
            // get wind force scale
            self.windForceLabel.text! = self.getWindParameters(for: windSpeed).0
            self.observEffectDescription.text! = self.getWindParameters(for: windSpeed).1
        }
        
        if let windDir = currentObservation["wind_dir"] as? String {
            self.windDirLabel.text! = windDir
        }
        
        if let windGusts = currentObservation["wind_gust_mph"] as? String {
            self.gustsLabel.text! = windGusts + " mph"
        }
        
        if let pressure = currentObservation["pressure_in"] as? String {
            self.pressureLabel.text! = pressure + " in"
        }
    }
    
    func getWindParameters(for windSpeed: Float) -> (String, String) {
        var force:String
        var observEffect:String
        
        switch windSpeed {
        case 0 ... 1.0 :
            force = "Calm"
            observEffect = "Vertical Smoke"
            
        case 1.1 ... 3.9 :
            force = "Light Air"
            observEffect = "Slight smoke drift"
            
        case 4.0 ... 7.9 :
            force = "Light Breeze"
            observEffect = "Leaves gently rustle"
            
        case 8.0 ... 12.9 :
            force = "Gentle Breeze"
            observEffect = "Leaves and twigs move"
            
        case 13.0 ... 18.9 :
            force = "Moderate Breeze"
            observEffect = "Moves small branches"
            
        case 19.0 ... 24.9 :
            force = "Fresh Breeze"
            observEffect = "Sways small leafy trees"
            
        case 25.0 ... 31.9 :
            force = "Strong Breeze"
            observEffect = "Sways large branches"
            
        case 32.0 ... 38.9 :
            force = "Moderate Gale"
            observEffect = "Trees sway"
            
        case 39.0 ... 46.9 :
            force = "Fresh Gale"
            observEffect = "Broken twigs, walking impeded"
            
        case 47.0 ... 54.9 :
            force = "Strong Gale"
            observEffect = "Chimneys, slates, hoardings damaged"
            
        case 55.0 ... 63.9 :
            force = "Whole Gale"
            observEffect = "Considerable damage"
            
        case 64.0 ... 75.9 :
            force = "Storm"
            observEffect = "Major Damage"
            
        case 76 ... 200:
            force = "Hurricane"
            observEffect = "Very dangerous tropical whirling winds"
            
        default:
            force = "N/A"
            observEffect = "N/A"
        }
        
        return (force, observEffect)
    }
    
    // UIStateRestoring protocol
    override func encodeRestorableState(with coder: NSCoder) {
        
        if let temp = self.tempLabel.text {
            coder.encode(temp, forKey: "temp")
        }
        
        //2
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        let temp = coder.decodeObject(forKey: "temp")
        //print(temp)
        super.decodeRestorableState(with: coder)
    }

}
