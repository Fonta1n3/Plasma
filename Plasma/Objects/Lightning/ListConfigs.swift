//
//  ListConfigs.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/4/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

// MARK: - ListConfigs
struct ListConfigs: Codable {
    let configs: Configs

    enum CodingKeys: String, CodingKey {
        case configs
    }
}

// MARK: - Configs
struct Configs: Codable {
    let experimentalOffers: ExperimentalOffers

    enum CodingKeys: String, CodingKey {
        case experimentalOffers = "experimental-offers"
    }
}

// MARK: - ExperimentalOffers
struct ExperimentalOffers: Codable {
    let set: Bool
    
    enum CodingKeys: String, CodingKey {
        case set
    }
}
