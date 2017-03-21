//
//  TransitSchedule.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-20.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation

class TransitSchedule {
    
    var pattern: String
    var destination: String
    var expLeaveTime: Date?
    var expCountDown: Int?
    var scheduleStatus: String?
    var isCancelled: Bool?
    var isStopCancelled: Bool?
    var isTripAdded: Bool?
    var isStopAdded: Bool?
    var lastUpdate: Date?
    
    init(pattern: String, destination: String) {
        self.pattern = pattern
        self.destination = destination
    }
    
    
}
