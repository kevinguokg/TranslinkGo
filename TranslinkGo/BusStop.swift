//
//  BusStop.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-20.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation

class BusStop: TransitStop {
    
    var stopNo: Int
    var bayNo: String?
    var onStreet: String?
    var atStreet: String?
    var wheelchairAccess: Int?
    var routes: String?
    
    init(name: String, stopNo: Int, city: String, lat: Double, long: Double) {
        self.stopNo = stopNo
        super.init(name: name, city: city, lat: lat, long: long)   
    }
    
}
