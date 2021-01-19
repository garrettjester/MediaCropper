//
//  File.swift
//  
//
//  Created by Garrett Jester on 1/15/21.
//

import UIKit

public extension UIColor {
    
    @nonobjc class var background: UIColor {
        dynamicColor(lightMode: .white, darkMode: .black)
    }
    
    @nonobjc class var selectionBlue: UIColor {
        return UIColor(red:0.20, green:0.62, blue:1.00, alpha:1.0)
    }
    
    @nonobjc class var grayText: UIColor {
        dynamicColor(lightMode: UIColor(red:0.71, green:0.71, blue:0.71, alpha:1.0),
                     darkMode: UIColor(red:0.71, green:0.71, blue:0.71, alpha:1.0))
    }
    
    @nonobjc class var separator: UIColor {
        return dynamicColor(lightMode: UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1.00),
                            darkMode: UIColor(red: 0.23, green: 0.23, blue: 0.23, alpha: 1.00))
    }
    
    class func dynamicColor(lightMode: UIColor, darkMode: UIColor) -> UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    /// Return the color for Dark Mode
                    return darkMode
                } else {
                    /// Return the color for Light Mode
                    return lightMode
                }
            }
        } else {
            /// Return a fallback color for iOS 12 and lower.
            return lightMode
        }
    }
}

