//
//  Pay.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/7/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

/*
 payment_preimage (secret): the proof of payment: SHA256 of this payment_hash
 payment_hash (hash): the hash of the payment_preimage which will prove payment
 created_at (number): the UNIX timestamp showing when this payment was initiated
 parts (u32): how many attempts this took
 amount_msat (msat): Amount the recipient received
 amount_sent_msat (msat): Total amount we sent (including fees)
 status (string): status of payment (one of "complete", "pending", "failed")
 destination (pubkey, optional): the final destination of the payment
 */

// MARK: - Pay
struct Pay: Codable {
    let paymentPreimage, paymentHash, status: String
    let parts, amountMsat, amountSentMsat: Int
    let destination: String?

    enum CodingKeys: String, CodingKey {
        case paymentPreimage = "payment_preimage"
        case paymentHash = "payment_hash"
        //case createdAt = "created_at"
        case amountMsat = "amount_msat"
        case amountSentMsat = "amount_sent_msat"
        case parts, status, destination
    }
}
