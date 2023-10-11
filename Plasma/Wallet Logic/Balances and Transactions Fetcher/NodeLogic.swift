//
//  NodeLogic.swift
//  BitSense
//
//  Created by Peter on 26/08/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import Foundation

class FetchFunds {
    
    static let sharedInstance = FetchFunds()
    
    private init() {}
    
    func balancesAndTxs(completion: @escaping ((balances: Balances?, txs: [Output], errorMessage: String?)) -> Void) {
        CoreDataService.retrieveEntity(entityName: .nodes) { [weak self] nodes in
            guard let self = self, let nodes = nodes else { return }
            
            var activeLightningNode = false
            
            for (i, node) in nodes.enumerated() {
                let nodeStr = NodeStruct(dictionary: node)
                
                if nodeStr.isActive {
                    activeLightningNode = true
                    
                    listFunds(completion: completion)
                }
                
                if i + 1 == nodes.count && !activeLightningNode {
                    completion((Balances(dictionary: [:]), [], nil))
                }
            }
        }
    }
    
        
    private func listFunds(completion: @escaping ((balances: Balances?, txs: [Output], errorMessage: String?)) -> Void) {
        var offchainMsatBalance = 0
        var onchainMsatBalance = 0
        var balanceDict: [String: Any] = [:]
        
        LightningRPC.sharedInstance.command(method: .listfunds, params: [:]) { (funds, errorDesc) in
            guard let funds = funds as? ListFunds else {
                completion((Balances(dictionary: [:]), [], errorDesc ?? ""))
                return
            }
            
            for channel in funds.channels {
                offchainMsatBalance += channel.ourAmountMsat
            }
            
            for output in funds.outputs {
                if output.status == "confirmed" {
                    onchainMsatBalance += output.amountMsat
                }
            }
                        
            balanceDict["offchainMsatBalance"] = offchainMsatBalance
            balanceDict["onchainMsatBalance"] = onchainMsatBalance
            balanceDict["totalMsatBalance"] = offchainMsatBalance + onchainMsatBalance
            completion((Balances(dictionary: balanceDict), funds.outputs, nil))
        }
    }
    
    
    func getCLTransactions(completion: @escaping ((response: OffchainTxs?, errorMessage: String?)) -> Void) {
        var offchainTxs: OffchainTxs = []
        LightningRPC.sharedInstance.command(method: .listsendpays, params: [:]) { [weak self] (listSendPays, errorDesc) in
            guard let self = self else { return }
            
            guard let listSendPays = listSendPays as? ListSendPays,
                  listSendPays.payments.count > 0 else {
                getPaid(offchainTxs: offchainTxs, completion: completion)
                return
            }
            
            for (i, payment) in listSendPays.payments.enumerated() {
                if payment.status != "failed" {
                    let date = date(unixStamp: payment.createdAt)
                    let dateString = dateString(date: date)
                    let amount = amounts(amountMsat: payment.amountSentMsat)
                    
                    let offChainTx: OffchainTx = .init(
                        bolt11: payment.bolt11 ?? "",
                        bolt12: payment.bolt12 ?? "",
                        amount: amount,
                        status: payment.status,
                        type: "Sent",
                        date: dateString,
                        description: payment.description ?? "",
                        sortDate: date
                        
                    )
                    
                    offchainTxs.append(offChainTx)
                }
                if i + 1 == listSendPays.payments.count {
                    getPaid(offchainTxs: offchainTxs, completion: completion)
                }
            }
        }
    }
    
    
    private func getPaid(offchainTxs: OffchainTxs, completion: @escaping ((response: OffchainTxs?, errorMessage: String?)) -> Void) {
        var offchainTxs: OffchainTxs = offchainTxs
        LightningRPC.sharedInstance.command(method: .listinvoices, params: [:]) { [weak self] (listInvoices, errorDesc) in
            guard let self = self else { return }
            
            guard let listInvoices = listInvoices as? ListInvoices,
                  listInvoices.invoices.count > 0 else {
                offchainTxs = offchainTxs.sorted{ $0.sortDate > $1.sortDate }
                completion((offchainTxs, nil))
                return
            }
            
            for (i, payment) in listInvoices.invoices.enumerated() {
                if payment.status == "paid" {
                    let date = date(unixStamp: payment.paidAt!)
                    let dateString = dateString(date: date)
                    let amount = amounts(amountMsat: payment.amountReceivedMsat!)
                    
                    let offChainTx: OffchainTx = .init(
                        bolt11: payment.bolt11 ?? "",
                        bolt12: payment.bolt12 ?? "",
                        amount: amount,
                        status: payment.status,
                        type: "Received",
                        date: dateString,
                        description: payment.description ?? "",
                        sortDate: date
                    )
                    
                    offchainTxs.append(offChainTx)
                }
                if i + 1 == listInvoices.invoices.count {
                    offchainTxs = offchainTxs.sorted{ $0.sortDate > $1.sortDate }
                    completion((offchainTxs, nil))
                }
            }
        }
    }
    
    
    private func date(unixStamp: Int) -> Date {
        return Date(timeIntervalSince1970: Double(unixStamp))
    }
    
    
    private func dateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM-dd-yyyy HH:mm"
        return dateFormatter.string(from: date)
    }
    
    
    private func amounts(amountMsat: Int) -> String {
        let denomination = UserDefaults.standard.object(forKey: "denomination") as? String ?? "BTC"
        let sats = amountMsat.msatToSats
        let btcDouble = sats.satsToBtc
        let btc = btcDouble.btcBalanceWithSpaces
        
        switch denomination {
        case "BTC":
            return btc
        case "SATS":
            return sats
        default:
            guard let fxRate = UserDefaults.standard.object(forKey: "fxRate") as? Double else { return "No fxRate."}
            return (btcDouble * fxRate).balanceText
        }
    }
}
