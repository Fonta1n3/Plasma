//
//  Decode.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/7/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation


// MARK: - DecodedInvoice
struct DecodedInvoice: Codable {
    let type: String
    let valid: Bool
    let offerDescription, offerNodeID, description, payee: String?
    let offerAmountMsat, invoiceAmountMsat, amountMsat, expiry, offerAbsoluteExpiry, createdAt: Int?

    enum CodingKeys: String, CodingKey {
        case type, valid, description, payee, expiry
        case offerDescription = "offer_description"
        case offerNodeID = "offer_node_id"
        case offerAmountMsat = "offer_amount_msat"
        case invoiceAmountMsat = "invoice_amount_msat"
        case amountMsat = "amount_msat"
        case offerAbsoluteExpiry = "offer_absolute_expiry"
        case createdAt = "created_at"
        
        
    }
}
