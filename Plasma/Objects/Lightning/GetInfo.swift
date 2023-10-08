//
//  GetInfo.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/4/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

// MARK: - GetInfo
struct GetInfo: Codable {
    let id, alias, color: String
    let numPeers, numPendingChannels, numActiveChannels, numInactiveChannels: Int
    let address, binding: [Address]
    let version: String
    let blockheight: Int
    let network: String
    let feesCollectedMsat: Int
    let lightningDir: String
    let ourFeatures: OurFeatures

    enum CodingKeys: String, CodingKey {
        case id, alias, color
        case numPeers = "num_peers"
        case numPendingChannels = "num_pending_channels"
        case numActiveChannels = "num_active_channels"
        case numInactiveChannels = "num_inactive_channels"
        case address, binding, version, blockheight, network
        case feesCollectedMsat = "fees_collected_msat"
        case lightningDir = "lightning-dir"
        case ourFeatures = "our_features"
    }
}

// MARK: - Address
struct Address: Codable {
    let type, address: String
    let port: Int
}

// MARK: - OurFeatures
struct OurFeatures: Codable {
    let ourFeaturesInit, node, channel, invoice: String

    enum CodingKeys: String, CodingKey {
        case ourFeaturesInit = "init"
        case node, channel, invoice
    }
}

