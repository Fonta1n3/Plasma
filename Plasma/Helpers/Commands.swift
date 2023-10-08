//
//  Commands.swift
//  BitSense
//
//  Created by Peter on 24/03/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//


public enum LIGHTNING_CLI: String {
    case listconfigs = "listconfigs"
    case getinfo = "getinfo"
    case invoice = "invoice"
    case offer = "offer"
    case fetchinvoice = "fetchinvoice"
    case newaddr = "newaddr"
    case listfunds = "listfunds"
    case listtransactions = "listtransactions"
    case txprepare = "txprepare"
    case txsend = "txsend"
    case pay = "pay"
    case decode = "decode"
    case decodepay = "decodepay"
    case connect = "connect"
    case fundchannel = "fundchannel"
    case fundchannel_start = "fundchannel_start"
    case fundchannel_complete = "fundchannel_complete"
    case listpeers = "listpeers"
    case listsendpays = "listsendpays"
    case listinvoices = "listinvoices"
    case withdraw = "withdraw"
    case getroute = "getroute"
    case listchannels = "listchannels"
    case sendpay = "sendpay"
    case rebalance = "rebalance"
    case keysend = "keysend"
    case listnodes = "listnodes"
    case sendmsg = "sendmsg"
    case recvmsg = "recvmsg"
    case close = "close"
    case disconnect = "disconnect"
    case listpeerchannels = "listpeerchannels"
}
