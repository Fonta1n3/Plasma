//
//  Balances.swift
//  BitSense
//
//  Created by Peter on 27/06/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import Foundation

public struct Balances: CustomStringConvertible {
    
    var onchainBalance: String
    var offchainBalance: String
    var totalBalance: String
    
    let onchainMsatBalance: Int
    let offchainMsatBalance: Int
    let totalMsatBalance: Int
        
    init(dictionary: [String: Any]) {
        onchainMsatBalance = dictionary["onchainMsatBalance"] as? Int ?? 0
        offchainMsatBalance = dictionary["offchainMsatBalance"] as? Int ?? 0
        totalMsatBalance = dictionary["totalMsatBalance"] as? Int ?? 0
        
        let denomination = UserDefaults.standard.object(forKey: "denomination") as? String ?? "BTC"
        switch denomination {
        case "BTC":
            onchainBalance = Double(onchainMsatBalance.msatToBtc)!.btcBalanceWithSpaces
            offchainBalance = Double(offchainMsatBalance.msatToBtc)!.btcBalanceWithSpaces
            totalBalance = Double((onchainMsatBalance + offchainMsatBalance).msatToBtc)!.btcBalanceWithSpaces
            
        case "SATS":
            onchainBalance = onchainMsatBalance.msatToSats
            offchainBalance = offchainMsatBalance.msatToSats
            totalBalance = (onchainMsatBalance + offchainMsatBalance).msatToSats
            
        default:
            onchainBalance = onchainMsatBalance.msatToFiat ?? "No fx rate."
            offchainBalance = offchainMsatBalance.msatToFiat ?? "No fx rate."
            totalBalance = totalMsatBalance.msatToFiat ?? "No fx rate."
        }
    }
    
    public var description: String {
        return "Balances as per the denomination setting."
    }
    
}
