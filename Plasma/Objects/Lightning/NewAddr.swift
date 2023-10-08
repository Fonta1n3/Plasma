//
//  NewAddr.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/7/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

// MARK: - NewAddr
struct NewAddr: Codable {
    let p2tr, bech32: String

    enum CodingKeys: String, CodingKey {
        case p2tr, bech32
    }
}
