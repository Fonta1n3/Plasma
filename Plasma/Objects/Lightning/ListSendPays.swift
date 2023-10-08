//
//  ListSendPays.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/5/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

/*
 id (u64): unique ID for this payment attempt
 groupid (u64): Grouping key to disambiguate multiple attempts to pay an invoice or the same payment_hash
 payment_hash (hash): the hash of the payment_preimage which will prove payment
 status (string): status of the payment (one of "pending", "failed", "complete")
 created_at (u64): the UNIX timestamp showing when this payment was initiated
 amount_sent_msat (msat): The amount sent
 partid (u64, optional): Part number (for multiple parts to a single payment)
 amount_msat (msat, optional): The amount delivered to destination (if known)
 destination (pubkey, optional): the final destination of the payment if known
 label (string, optional): the label, if given to sendpay
 bolt11 (string, optional): the bolt11 string (if pay supplied one)
 description (string, optional): the description matching the bolt11 description hash (if pay supplied one)
 bolt12 (string, optional): the bolt12 string (if supplied for pay: experimental-offers only).
 If status is "complete":

 payment_preimage (secret): the proof of payment: SHA256 of this payment_hash
 If status is "failed":

 erroronion (hex, optional): the onion message returned
 */

// MARK: - ListSendPays
struct ListSendPays: Codable {
    let payments: [Payment]
}

// MARK: - Payment
struct Payment: Codable {
    let id: Int
    let paymentPreimage: String?
    let createdAt: Int
    let amountSentMsat, groupid: Int
    let destination, label, bolt11, bolt12, description, errorOnion: String?
    let completedAt: Int
    let paymentHash, status: String
    let partId, amountMsat: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case amountMsat = "amount_msat"
        case label
        case paymentPreimage = "payment_preimage"
        case createdAt = "created_at"
        case bolt11, bolt12
        case amountSentMsat = "amount_sent_msat"
        case groupid, destination, description
        case completedAt = "completed_at"
        case paymentHash = "payment_hash"
        case status
        case partId = "part_id"
        case errorOnion = "erroronion"
    }
}
