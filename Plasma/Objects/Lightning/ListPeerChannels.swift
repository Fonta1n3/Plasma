//
//  ListPeerChannels.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/4/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

// MARK: - ListPeerChannels
struct ListPeerChannels: Codable {
    let channels: [PeerChannel]
}

// MARK: - Channel
struct PeerChannel: Codable {
    let channelPrivate: Bool
    let alias: Alias
    let fundingOutnum, theirReserveMsat, direction: Int
    let state: String
    let maxAcceptedHtlcs, minimumHtlcInMsat: Int
    let scratchTxid: String
    let inPaymentsOffered, feeProportionalMillionths, inPaymentsFulfilled, outPaymentsFulfilled: Int
    let ourToSelfDelay, dustLimitMsat, totalMsat: Int
    let closeTo: String
    let inOfferedMsat, outFulfilledMsat: Int
    let shortChannelID: String?
    let stateChanges: [StateChange]
    let outPaymentsOffered, feeBaseMsat: Int
    //let htlcs: [JSONAny]
    let opener: String
    let maxTotalHtlcInMsat: Double
    let theirToSelfDelay: Int
    let closeToAddr: String
    let toUsMsat: Int
    let channelID: String
    let status: [String]
    let funding: Funding
    let maxToUsMsat, ourReserveMsat: Int
    let fundingTxid: String
    let maximumHtlcOutMsat: Int
    let peerConnected: Bool
    let features: [String]
    let receivableMsat: Int
    let owner: String
    let minToUsMsat, minimumHtlcOutMsat, inFulfilledMsat: Int
    let feerate: Feerate
    let outOfferedMsat: Int
    let peerID: String
    let spendableMsat, lastTxFeeMsat: Int
    let channelType: ChannelType

    enum CodingKeys: String, CodingKey {
        case channelPrivate = "private"
        case alias
        case fundingOutnum = "funding_outnum"
        case theirReserveMsat = "their_reserve_msat"
        case direction, state
        case maxAcceptedHtlcs = "max_accepted_htlcs"
        case minimumHtlcInMsat = "minimum_htlc_in_msat"
        case scratchTxid = "scratch_txid"
        case inPaymentsOffered = "in_payments_offered"
        case feeProportionalMillionths = "fee_proportional_millionths"
        case inPaymentsFulfilled = "in_payments_fulfilled"
        case outPaymentsFulfilled = "out_payments_fulfilled"
        case ourToSelfDelay = "our_to_self_delay"
        case dustLimitMsat = "dust_limit_msat"
        case totalMsat = "total_msat"
        case closeTo = "close_to"
        case inOfferedMsat = "in_offered_msat"
        case outFulfilledMsat = "out_fulfilled_msat"
        case shortChannelID = "short_channel_id"
        case stateChanges = "state_changes"
        case outPaymentsOffered = "out_payments_offered"
        case feeBaseMsat = "fee_base_msat"
        case opener
        case maxTotalHtlcInMsat = "max_total_htlc_in_msat"
        case theirToSelfDelay = "their_to_self_delay"
        case closeToAddr = "close_to_addr"
        case toUsMsat = "to_us_msat"
        case channelID = "channel_id"
        case status, funding
        case maxToUsMsat = "max_to_us_msat"
        case ourReserveMsat = "our_reserve_msat"
        case fundingTxid = "funding_txid"
        case maximumHtlcOutMsat = "maximum_htlc_out_msat"
        case peerConnected = "peer_connected"
        case features
        case receivableMsat = "receivable_msat"
        case owner
        case minToUsMsat = "min_to_us_msat"
        case minimumHtlcOutMsat = "minimum_htlc_out_msat"
        case inFulfilledMsat = "in_fulfilled_msat"
        case feerate
        case outOfferedMsat = "out_offered_msat"
        case peerID = "peer_id"
        case spendableMsat = "spendable_msat"
        case lastTxFeeMsat = "last_tx_fee_msat"
        case channelType = "channel_type"
    }
}

// MARK: - Alias
struct Alias: Codable {
    let local, remote: String
}

// MARK: - ChannelType
struct ChannelType: Codable {
    let bits: [Int]
    let names: [String]
}

// MARK: - Feerate
struct Feerate: Codable {
    let perkw, perkb: Int
}

// MARK: - Funding
struct Funding: Codable {
    let remoteFundsMsat, localFundsMsat, pushedMsat: Int

    enum CodingKeys: String, CodingKey {
        case remoteFundsMsat = "remote_funds_msat"
        case localFundsMsat = "local_funds_msat"
        case pushedMsat = "pushed_msat"
    }
}

// MARK: - StateChange
struct StateChange: Codable {
    let oldState, newState, timestamp, message: String
    let cause: String

    enum CodingKeys: String, CodingKey {
        case oldState = "old_state"
        case newState = "new_state"
        case timestamp, message, cause
    }
}
