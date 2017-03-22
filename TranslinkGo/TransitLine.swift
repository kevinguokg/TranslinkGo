//
//  TransitLine.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-20.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation

class TransitLine {
    var routeNo: String
    var routeName: String
    var direction: String
    var schedules: [TransitSchedule]?
    
    init(routeNo: String, routeName: String, direction: String) {
        self.routeNo = routeNo
        self.routeName = routeName
        self.direction = direction
    }
    
    
}
