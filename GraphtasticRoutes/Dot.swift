//
//  Dot.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 9/5/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import UIKit

class Dot: UIView {
    var color: UIColor = UIColor.black
    
    init(_ frame: CGRect = CGRect.zero, color: UIColor) {
        super.init(frame: frame)
        self.color = color
    }
    
    lazy var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        layer.fillColor = self.color.cgColor
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !frame.isEmpty { self.layer.addSublayer(circleLayer) }
        // self .circle lyaer frame - cg rwxr
        
    }
    
}
