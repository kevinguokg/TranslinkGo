//
//  BusStopLocAnnotation.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-20.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class BusStopLocAnnotation: NSObject, MKAnnotation {
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var info: String
    
    init(title: String, coordinate: CLLocationCoordinate2D, info: String) {
        self.title = title
        self.coordinate = coordinate
        self.info = info
    }
}
