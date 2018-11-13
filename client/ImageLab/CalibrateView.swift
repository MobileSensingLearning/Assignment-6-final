//
//  CalibrateView.swift
//  HTTPSwiftExample
//
//  Created by Brandon McFarland on 11/9/18.
//  Copyright © 2018 Eric Larson. All rights reserved.
//

import Foundation
import UIKit

class CalibrateView: UIView {
    
    override func draw(_ rect: CGRect) {
        
        let cgContext = UIGraphicsGetCurrentContext()
        cgContext?.move(to: CGPoint(x: rect.minX, y: rect.minY))
        cgContext?.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        cgContext?.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        cgContext?.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        cgContext?.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        cgContext?.setStrokeColor(UIColor.gray.withAlphaComponent(1.0).cgColor)
        cgContext?.setLineWidth(15.0)
        cgContext?.strokePath()
    }
 
}


