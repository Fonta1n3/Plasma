//
//  OffchainTxs.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/5/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation


// MARK: - OffchainTx
struct OffchainTx: Codable {
    let bolt11, bolt12, amount, status, type: String
    let date, description: String
    let sortDate: Date
}

// MARK: - OffchainTxs
typealias OffchainTxs = [OffchainTx]
