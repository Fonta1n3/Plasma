//
//  Output.swift
//  FullyNoded
//
//  Created by Peter Denton on 9/24/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

/*
 txid (txid): the ID of the spendable transaction
 output (u32): the index within txid
 amount_msat (msat): the amount of the output
 scriptpubkey (hex): the scriptPubkey of the output
 status (string) (one of "unconfirmed", "confirmed", "spent", "immature")
 reserved (boolean): whether this UTXO is currently reserved for an in-flight tx
 address (string, optional): the bitcoin address of the output
 redeemscript (hex, optional): the redeemscript, only if it's p2sh-wrapped
 */

public struct TxOutput: CustomStringConvertible, Codable {
    
    let txid: String
    let output: UInt32
    let amount_msat: Int
    let scriptpubkey: String
    let status: String
    let reserved: Bool
    let address: String?
    let redeemscript: String?
    let blockheight: Int?
    
    init(_ dictionary: [String: Any]) {
        txid = dictionary["txid"] as! String
        output = dictionary["output"] as! UInt32
        amount_msat = dictionary["amount_msat"] as! Int
        scriptpubkey = dictionary["scriptpubkey"] as! String
        status = dictionary["status"] as! String
        reserved = dictionary["reserved"] as! Bool
        address = dictionary["address"] as? String
        redeemscript = dictionary["redeemscript"] as? String
        blockheight = dictionary["blockheight"] as? Int
    }
    
    public var description: String {
        return ""
    }
    
}
