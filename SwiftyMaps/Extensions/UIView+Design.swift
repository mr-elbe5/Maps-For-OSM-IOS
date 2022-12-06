/*
 My Private Track
 App for creating a diary with entry based on time and map location using text, photos, audios and videos
 Copyright: Michael Rönnau mr@elbe5.de
 */

import Foundation

import UIKit

extension UIView{
    
    var transparentColor : UIColor{
        if isDarkMode{
            return UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.6)
        }
        else{
            return UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
        }
    }
    
    var isDarkMode: Bool {
        self.traitCollection.userInterfaceStyle == .dark
    }
    
    @discardableResult
    func setBackground(_ color:UIColor) -> UIView{
        backgroundColor = color
        return self
    }
    
    @discardableResult
    func setRoundedBorders(radius: CGFloat = 5) -> UIView{
        layer.borderWidth = 0.5
        layer.cornerRadius = radius
        layer.masksToBounds = true
        return self
    }
    
    @discardableResult
    func setGrayRoundedBorders(radius: CGFloat = 5) -> UIView{
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = radius
        layer.masksToBounds = true
        return self
    }
    
}

