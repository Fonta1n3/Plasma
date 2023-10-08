//
//  Invoice.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/4/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

/*
 warning_capacity: even using all possible channels, there's not enough incoming capacity to pay this invoice.
 warning_offline: there would be enough incoming capacity, but some channels are offline, so there isn't.
 warning_deadends: there would be enough incoming capacity, but some channels are dead-ends (no other public channels from those peers), so there isn't.
 warning_private_unused: there would be enough incoming capacity, but some channels are unannounced and exposeprivatechannels is false, so there isn't.
 warning_mpp
 */

// MARK: - Invoice
struct Invoice: Codable {
    let paymentHash,
        paymentSecret,
        bolt11: String
    let warningDeadends,
        warningCapacity,
        warningOffline,
        warningPrivateUnused,
        warningMpp: String?
    let expiresAt: Int

    enum CodingKeys: String, CodingKey {
        case paymentHash = "payment_hash"
        case paymentSecret = "payment_secret"
        case warningDeadends = "warning_deadends"
        case warningCapacity = "warning_capacity"
        case warningOffline = "warning_offline"
        case warningPrivateUnused = "warning_private_unused"
        case warningMpp = "warning_mpp"
        case bolt11
        case expiresAt = "expires_at"
    }
}
