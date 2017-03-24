//
//  TransitBus.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-23.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation

class TransitBus: TransitVehicle {
    var tripId: String
    var routeNo: String
    var direction: String?
    var destination: String?
    var pattern: String?
    var recordedTime: Date?
    
    init(vehicleNo: String, tripId: String, routeNo: String) {
        self.tripId = tripId
        self.routeNo = routeNo
        
        super.init(vehicleNo: vehicleNo)
    }
}
