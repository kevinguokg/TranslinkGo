//
//  MapCenterOverlayButton.swift
//  TranslinkGo
//
//  Created by Kevin Guo on 2017-03-24.
//  Copyright © 2017 Kevin Guo. All rights reserved.
//

import Foundation
import UIKit

class MapCenterOverlayButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let outerCiecleLayer = CAShapeLayer()
        outerCiecleLayer.path = UIBezierPath(arcCenter: self.center, radius: self.bounds.width * 0.45, startAngle: CGFloat(-M_PI_2), endAngle: CGFloat(M_PI_2 * 3), clockwise: true).cgPath
        outerCiecleLayer.fillColor = UIColor.white.cgColor
        outerCiecleLayer.shadowColor = UIColor.darkGray.cgColor
        outerCiecleLayer.shadowPath = UIBezierPath(arcCenter: self.center, radius: self.bounds.width * 0.5, startAngle: CGFloat(-M_PI_2), endAngle: CGFloat(M_PI_2 * 3), clockwise: true).cgPath
        //        outerCiecleLayer.shadowOpacity = 0.9
        outerCiecleLayer.shadowRadius = 5
        self.layer.addSublayer(outerCiecleLayer)
        
        print(self.center)
        let innerCiecleLayer = CAShapeLayer()
        innerCiecleLayer.path = UIBezierPath(arcCenter: self.center, radius: self.bounds.width * 0.35, startAngle: CGFloat(-M_PI_2), endAngle: CGFloat(M_PI_2 * 3), clockwise: true).cgPath
        innerCiecleLayer.fillColor = UIColor.purple.cgColor
        self.layer.addSublayer(innerCiecleLayer)
    }
}
