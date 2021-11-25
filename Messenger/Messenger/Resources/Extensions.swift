//
//  Extensions.swift
//  Messenger
//
//  Created by Марія Кухарчук on 11.11.2021.
//

import Foundation
import UIKit

extension UIView{
    
    public var width: CGFloat{
        return self.frame.size.width
    }
    
    public var height: CGFloat{
        return self.frame.size.height
    }
    
    public var top: CGFloat{
        return self.frame.origin.y
    }
    
    public var buttom: CGFloat{
        return self.frame.size.height + self.frame.origin.y
    }
    
    public var left: CGFloat{
        return self.frame.origin.x
    }
    
    public var right: CGFloat{
        return self.frame.size.width + self.frame.origin.x
    }
}



extension UIColor {
    //0x0EAB19
    struct CustomColors{
        static let lightPink = UIColor.init(netHex: 0xF68DA0)
        static let lightGreen = UIColor.init(netHex: 0x0FBD1B)
        static let strongRed = UIColor.init(netHex: 0xBD1B0F)
        
    }
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }

}

extension StringProtocol{
    public subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

extension String{
    func parseToSafeEmail() -> String {
        var safeEmail  = self.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        for i in 1...safeEmail.count
        {
            if safeEmail[i].isNumber {
            if safeEmail[i-1] == "-" || safeEmail[i-1].isNumber{
                break
            }
                safeEmail.insert("-", at: safeEmail.index(safeEmail.startIndex, offsetBy: i))
            }
        }
        return safeEmail
    }
}

extension Notification.Name{
    static let didLogInNotification = Notification.Name("didLogInNotification")
}
