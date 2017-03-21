//
//  TranslinkLineCell.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-17.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation
import UIKit

class TranslinkLineCell: UITableViewCell {
    
    @IBOutlet weak var stopNoLabel: UILabel!
    @IBOutlet weak var stopLocLabel: UILabel!
    @IBOutlet weak var transitLineLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var wheelChairImageLabel: UIImageView!
    
    @IBOutlet weak var bottomView: UIView!
    
    @IBOutlet weak var bottomViewContraint: NSLayoutConstraint!
    
    var isExpanded: Bool = false {
        didSet {
            if !isExpanded {
                self.bottomViewContraint.constant = 0.0
                self.bottomView.isHidden = true
            } else {
                self.bottomViewContraint.constant = 30.0
                self.bottomView.isHidden = false
            }
        }
    }
}
