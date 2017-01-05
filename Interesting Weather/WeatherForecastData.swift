//
//  WeatherForecastData.swift
//  Interesting Weather
//
//  Created by Mykola Tarasov on 1/3/17.
//  Copyright © 2017 Nikolai Tarasov. All rights reserved.
//

import UIKit

class WeatherForecastData: NSObject {
    
    var data: Dictionary<String, Any>
    
    init(data: Dictionary<String, Any>) {
        self.data = data
    }

}
