//
//  Offer.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/4/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

// MARK: - Offer
struct Offer: Codable {
    let used: Bool
    let offerID: String
    let singleUse, active, created: Bool
    let bolt12: String

    enum CodingKeys: String, CodingKey {
        case used
        case offerID = "offer_id"
        case singleUse = "single_use"
        case active, created, bolt12
    }
}
