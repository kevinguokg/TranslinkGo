//
//  TransitEstimateCell.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-21.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation
import UIKit

class TransitEstimateCell: UITableViewCell {
    
    @IBOutlet weak var transitLineNoLabel: UILabel!
    @IBOutlet weak var transitDestinationLabel: UILabel!
    @IBOutlet weak var transitLocationLabel: UILabel!
    @IBOutlet weak var recentScheduleLabel: UILabel!
    @IBOutlet weak var recentScheduleUnitLabel: UILabel!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomViewHeightConstraint: NSLayoutConstraint!
    
    var isExpanded: Bool = false {
        didSet {
            if !self.isExpanded {
                self.bottomViewHeightConstraint.constant = 0.0
                self.bottomView.isHidden = true
            } else {
                self.bottomViewHeightConstraint.constant = 30.0
                self.bottomView.isHidden = false
            }
        }
    }
}
