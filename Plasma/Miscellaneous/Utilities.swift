//
//  Utilities.swift
//  BitSense
//
//  Created by Peter on 08/08/18.
//  Copyright © 2018 Fontaine. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


enum Vibration {
        case error
        case success
        case warning
        case light
        case medium
        case heavy
        @available(iOS 13.0, *)
        case soft
        @available(iOS 13.0, *)
        case rigid
        case selection
        case oldSchool

        public func vibrate() {
            switch self {
            case .error:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .warning:
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .light:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .medium:
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case .heavy:
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case .soft:
                if #available(iOS 13.0, *) {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            case .rigid:
                if #available(iOS 13.0, *) {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
            case .selection:
                UISelectionFeedbackGenerator().selectionChanged()
            case .oldSchool:
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }
    }

public func decryptedValue(_ encryptedValue: Data) -> String? {
    guard let decrypted = Crypto.decrypt(encryptedValue) else { return nil }
    
    return decrypted.utf8String ?? ""
}

/// Call this method to retrive active wallet. This method seaches the device's storage. NOT the node.
/// - Parameter completion: Active wallet

public func showAlert(vc: UIViewController?, title: String, message: String) {
    if let vc = vc {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
}

public func impact() {
    if #available(iOS 10.0, *) {
        let impact = UIImpactFeedbackGenerator()
        DispatchQueue.main.async {
            impact.impactOccurred()
        }
    } else {
        // Fallback on earlier versions
    }
}

public func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0...length-1).map{ _ in letters.randomElement()! })
}

public func rounded(number: Double) -> Double {
    return Double(round(100000000*number)/100000000)
    
}

public func displayAlert(viewController: UIViewController?, isError: Bool, message: String) {
    if viewController != nil {
        showAlert(vc: viewController, title: "Error", message: message)
    }
}

public func hexStringToUIColor(hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }

    if ((cString.count) != 6) {
        return UIColor.gray
    }

    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

public var authTimeout: Int {
    return 360
}

public let currencies:[[String:String]] = [
    ["USD": "$"],
    ["GBP": "£"],
    ["EUR": "€"],
    ["AUD":"$"],
    ["BRL": "R$"],
    ["CAD": "$"],
    ["CHF": "CHF "],
    ["CLP": "$"],
    ["CNY": "¥"],
    ["DKK": "kr"],
    ["HKD": "$"],
    ["INR": "₹"],
    ["ISK": "kr"],
    ["JPY": "¥"],
    ["KRW": "₩"],
    ["NZD": "$"],
    ["PLN": "zł"],
    ["RUB": "₽"],
    ["SEK": "kr"],
    ["SGD": "$"],
    ["THB": "฿"],
    ["TRY": "₺"],
    ["TWD": "NT$"]
]

public let blockchainInfoCurrencies:[[String:String]] = [
    ["USD": "dollarsign.circle"],
    ["GBP": "sterlingsign.circle"],
    ["EUR": "eurosign.circle"],
    ["AUD":"dollarsign.circle"],
    ["BRL": "brazilianrealsign.circle"],
    ["CAD": "dollarsign.circle"],
    ["CHF": "francsign.circle"],
    ["CLP": "dollarsign.circle"],
    ["CNY": "yensign.circle"],
    ["DKK": "k.circle"],
    ["HKD": "dollarsign.circle"],
    ["INR": "indianrupeesign.circle"],
    ["ISK": "k.circle"],
    ["JPY": "yensign.circle"],
    ["KRW": "wonsign.circle"],
    ["NZD": "dollarsign.circle"],
    ["PLN": "z.circle"],
    ["RUB": "rublesign.circle"],
    ["SEK": "k.circle"],
    ["SGD": "dollarsign.circle"],
    ["THB": "bahtsign.circle"],
    ["TRY": "turkishlirasign.circle"],
    ["TWD": "dollarsign.circle"]
]

public let coindeskCurrencies:[[String:String]] = [
    ["USD": "dollarsign.circle"],
    ["GBP": "sterlingsign.circle"],
    ["EUR": "eurosign.circle"]
]

public let denominations:[String] = [
    "BTC",
    "SATS",
    UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
]

public func shakeAlert(viewToShake: UIView) {
    let animation = CABasicAnimation(keyPath: "position")
    animation.duration = 0.07
    animation.repeatCount = 4
    animation.autoreverses = true
    animation.fromValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x - 10, y: viewToShake.center.y))
    animation.toValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x + 10, y: viewToShake.center.y))
    
    DispatchQueue.main.async {
        viewToShake.layer.add(animation, forKey: "position")
    }
}

public func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}
