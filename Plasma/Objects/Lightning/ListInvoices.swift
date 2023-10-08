//
//  ListInvoices.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/4/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

/*
 label (string): unique label supplied at invoice creation
 payment_hash (hash): the hash of the payment_preimage which will prove payment
 status (string): Whether it's paid, unpaid or unpayable (one of "unpaid", "paid", "expired")
 expires_at (u64): UNIX timestamp of when it will become / became unpayable
 created_index (u64): 1-based index indicating order this invoice was created in (added v23.08)
 description (string, optional): description used in the invoice
 amount_msat (msat, optional): the amount required to pay this invoice
 bolt11 (string, optional): the BOLT11 string (always present unless bolt12 is)
 bolt12 (string, optional): the BOLT12 string (always present unless bolt11 is)
 local_offer_id (hash, optional): the id of our offer which created this invoice (experimental-offers only).
 invreq_payer_note (string, optional): the optional invreq_payer_note from invoice_request which created this invoice (experimental-offers only).
 updated_index (u64, optional): 1-based index indicating order this invoice was changed (only present if it has changed since creation) (added v23.08)
 If status is "paid":

 pay_index (u64): Unique incrementing index for this payment
 amount_received_msat (msat): the amount actually received (could be slightly greater than amount_msat, since clients may overpay)
 paid_at (u64): UNIX timestamp of when it was paid
 payment_preimage (secret): proof of payment
 */

// MARK: - ListInvoices
struct ListInvoices: Codable {
    let invoices: [OurInvoice]
}

// MARK: - Invoice
struct OurInvoice: Codable {
    let status, label, paymentHash: String
    let expiresAt: Int
    let bolt12, bolt11, description, localOfferId, invreqPayerNote, paymentPreimage: String?
    let paidAt, payIndex, amountReceivedMsat, updatedIndex, createdIndex, amountMsat: Int?

    enum CodingKeys: String, CodingKey {
        case status, label
        case bolt11, bolt12, description
        case expiresAt = "expires_at"
        case paymentHash = "payment_hash"
        case amountMsat = "amount_msat"
        case paymentPreimage = "payment_preimage"
        case paidAt = "paid_at"
        case payIndex = "pay_index"
        case amountReceivedMsat = "amount_received_msat"
        case localOfferId = "local_offer_id"
        case invreqPayerNote = "invreq_payer_note"
        case updatedIndex = "updated_index"
        case createdIndex = "created_index"
        
    }
}
