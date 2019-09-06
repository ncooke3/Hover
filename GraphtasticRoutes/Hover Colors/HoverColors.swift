//
//  HoverColors.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 8/31/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import UIKit

enum Colors {
    
    case darkRed
    case red
    case orange
    case lightOrange
    case yellow
    case custom(hexString: String, alpha: Double)
    
    var value: UIColor {
        switch self {
        case .darkRed:
            return UIColor(hexString: "#2D1523")
        case .red:
            return UIColor(hexString: "#CB2614")
        case .orange:
            return UIColor(hexString: "#FD6E07")
        case .lightOrange:
            return UIColor(hexString: "#F18E35")
        case .yellow:
            return UIColor(hexString: "#E7B32B")
        case .custom(let hexValue, let opacity):
            return UIColor(hexString: hexValue).withAlphaComponent(CGFloat(opacity))
        }
    }
    
    func withAlpha(_ alpha: Double) -> UIColor {
        return self.value.withAlphaComponent(CGFloat(alpha))
    }
}

extension UIColor {

    convenience init(hexString: String) {
        
        let hexString: String = (hexString as NSString).trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner          = Scanner(string: hexString as String)
        
        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    func toHexString() -> String {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02x%02x%02x%02x", Int(red * 255), Int(green * 255), Int(blue * 255), Int(alpha * 255))
    }
}

