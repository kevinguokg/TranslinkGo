//
//  TransitStop.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-20.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation

class TransitStop {

    var name: String
    var city: String
    var latitude: Double
    var longitude: Double
    var distance: Int?
    
    init(name: String, city: String, lat: Double, long: Double) {
        self.name = name
        self.city = city
        self.latitude = lat
        self.longitude = long
    }
    
    
    
}
