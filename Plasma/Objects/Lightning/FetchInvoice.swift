//
//  FetchInvoice.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/7/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

/*
 invoice (string): The BOLT12 invoice we fetched
 changes (object): Summary of changes from offer:
 next_period (object, optional): Only for recurring invoices if the next period is under the recurrence_limit:

 */

// MARK: - FetchInvoice
struct FetchInvoice: Codable {
    let invoice: String
    let changes: Changes
    let nextPeriod: NextPeriod?

    enum CodingKeys: String, CodingKey {
        case changes
        case invoice
        case nextPeriod = "next_period"
    }
}


/*

 description_appended (string, optional): extra characters appended to the description field.
 description (string, optional): a completely replaced description field
 vendor_removed (string, optional): The vendor from the offer, which is missing in the invoice
 vendor (string, optional): a completely replaced vendor field
 amount_msat (msat, optional): the amount, if different from the offer amount multiplied by any quantity (or the offer had no amount, or was not in BTC).
 */

// MARK: - Changes
struct Changes: Codable {
    let descriptionAppended, vendor: String?
    let description, vendorRemoved: String?
    let amountMsat: Int?
    

    enum CodingKeys: String, CodingKey {
        case descriptionAppended = "description_appended"
        case description, vendor
        case vendorRemoved = "vendor_removed"
        case amountMsat = "amount_msat"
    }
}

/*
 counter (u64): the index of the next period to fetchinvoice
 starttime (u64): UNIX timestamp that the next period starts
 endtime (u64): UNIX timestamp that the next period ends
 paywindow_start (u64): UNIX timestamp of the earliest time that the next invoice can be fetched
 paywindow_end (u64): UNIX timestamp of the latest time that the next invoice can be fetched
 */

// MARK: - NextPeriod
struct NextPeriod: Codable {
    let counter, starttime, endtime, paywindowStart, paywindowEnd: Int

    enum CodingKeys: String, CodingKey {
        case paywindowEnd = "paywindow_end"
        case paywindowStart = "paywindow_start"
        case counter, starttime, endtime
    }
}
