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

