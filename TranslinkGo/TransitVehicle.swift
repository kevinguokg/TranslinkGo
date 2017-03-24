//
//  TransitVehicle.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-23.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation

class TransitVehicle {
    var vehicleNo: String
    var latitude: Double?
    var longitude: Double?
    
    init(vehicleNo: String) {
        self.vehicleNo = vehicleNo
    }
}
