//
//  GradientView.swift
//  FluidInterfaces
//
//  Created by Nathan Gitter on 7/15/18.
//  Copyright © 2018 Nathan Gitter. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    public var topColor: UIColor = .white {
        didSet {
            updateGradientColors()
        }
    }
    
    public var bottomColor: UIColor = .black {
        didSet {
            updateGradientColors()
        }
    }
    
    /// The corner radius of the view.
    /// If no value is provided, the default is 20% of the view's width.
    public var cornerRadius: CGFloat? {
        didSet {
            layoutSubviews()
        }
    }
    
    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0.75)
        return gradientLayer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        layer.addSublayer(gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius ?? bounds.width * 0.2).cgPath
        layer.mask = maskLayer
    }
    
    private func updateGradientColors() {
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
    }
    
}

extension UISpringTimingParameters {
    
    public convenience init(damping: CGFloat, response: CGFloat, initialVelocity: CGVector = .zero) {
        let stiffness = pow(2 * .pi / response, 2)
        let damp = 4 * .pi * damping / response
        self.init(mass: 1, stiffness: stiffness, damping: damp, initialVelocity: initialVelocity)
    }
    
}


class InstantPanGestureRecognizer: UIPanGestureRecognizer {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.state = .began
    }
    
}
