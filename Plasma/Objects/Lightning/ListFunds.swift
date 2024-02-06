//
//  ListFunds.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/4/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

// MARK: - Welcome
struct ListFunds: Codable {
    let channels: [Channel]
    let outputs: [Output]
}

// MARK: - Channel
struct Channel: Codable {
    let amountMsat: Int
    let channelID: String
    let connected: Bool
    let fundingOutput: Int
    let fundingTxid: String
    let ourAmountMsat: Int
    let peerID, state: String
    let shortChannelID: String?

    enum CodingKeys: String, CodingKey {
        case amountMsat = "amount_msat"
        case channelID = "channel_id"
        case connected
        case fundingOutput = "funding_output"
        case fundingTxid = "funding_txid"
        case ourAmountMsat = "our_amount_msat"
        case peerID = "peer_id"
        case shortChannelID = "short_channel_id"
        case state
    }
}

// MARK: - Output
struct Output: Codable {
    let address: String
    let amountMsat, output: Int
    let blockheight: Int?
    let reserved: Bool
    let scriptpubkey, status, txid: String

    enum CodingKeys: String, CodingKey {
        case address
        case amountMsat = "amount_msat"
        case blockheight, output, reserved, scriptpubkey, status, txid
    }
}
