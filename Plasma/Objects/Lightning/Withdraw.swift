//
//  Withdraw.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/7/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation
/*
 tx (hex): the fully signed bitcoin transaction
 txid (txid): the transaction id of tx
 psbt (string): the PSBT representing the unsigned transaction
 */

// MARK: - Withdraw
struct Withdraw: Codable {
    let tx, txid, psbt: String

    enum CodingKeys: String, CodingKey {
        case tx, txid, psbt
    }
}
