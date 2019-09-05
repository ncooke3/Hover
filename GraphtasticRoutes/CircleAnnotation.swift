//
//  CircleAnnotation.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 9/5/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import MapKit

class CircleAnnotation: MKAnnotationView {
    public static let annotationFrame: CGRect = CGRect(x: 0, y: 0, width: 10, height: 10)
    
    enum SelectedState {
        case unselected
        case start
        case goal
    }
    
    var state: SelectedState = .unselected
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        print("we killin it", annotation is VertexPointAnnotation)
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = CircleAnnotation.annotationFrame
        self.backgroundColor = .clear
        
        let circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(ovalIn: CircleAnnotation.annotationFrame).cgPath
        circleLayer.fillColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value.cgColor
        self.layer.addSublayer(circleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented!")
    }
    
    public func shrink(the view: MKAnnotationView) {
        self.layer.sublayers?.forEach {
            layer in
            if layer is CAShapeLayer {
                let gotem = layer as! CAShapeLayer
                
                UIView.animate(withDuration: 0.1) {
                    gotem.fillColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value.cgColor
                    view.transform = CGAffineTransform.identity
                }
            }
        }
    }
    
    public func expand(the view: MKAnnotationView, with cgcolor: CGColor) {
        self.layer.sublayers?.forEach {
            layer in
            if layer is CAShapeLayer {
                let gotem = layer as! CAShapeLayer
                
                UIView.animate(withDuration: 0.1) {
                    gotem.fillColor = cgcolor
                    view.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                }
            }
        }
    }
    
}
