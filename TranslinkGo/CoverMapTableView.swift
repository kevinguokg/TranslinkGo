//
//  CoverMapTableView.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-17.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation
import UIKit

class CoverMapTableView: UITableView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if (point.y < 0) {
            return nil
        }
        
        return view
    }
    
}

