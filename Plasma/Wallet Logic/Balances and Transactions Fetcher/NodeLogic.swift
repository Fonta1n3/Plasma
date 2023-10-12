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
        LightningRPC.sharedInstance.command(method: .listsendpays, params: ["status":"complete"]) { [weak self] (listSendPays, errorDesc) in
            guard let self = self else { return }
            
            guard let listSendPays = listSendPays as? ListSendPays,
                  listSendPays.payments.count > 0 else {
                getPaid(offchainTxs: offchainTxs, completion: completion)
                return
            }
            
            let lastHundred = listSendPays.payments.suffix(100)
            
            for (i, payment) in lastHundred.enumerated() {
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
                
                if i + 1 == lastHundred.count {
                    getPaid(offchainTxs: offchainTxs, completion: completion)
                }
            }
        }
    }
    
    
    private func getPaid(offchainTxs: OffchainTxs, completion: @escaping ((response: OffchainTxs?, errorMessage: String?)) -> Void) {
        var offchainTxs: OffchainTxs = offchainTxs
        LightningRPC.sharedInstance.command(method: .sql, params: ["query": "SELECT * FROM invoices WHERE 'paid' in (status)"]) { [weak self] (response, errorDesc) in
            guard let self = self else { return }
            
            guard let response = response as? [String: Any],
                  let rows = response["rows"] as? [NSArray] else {
                completion((nil, errorDesc ?? "Unknown error."))
                return
            }
            
            guard rows.count > 0 else {
                offchainTxs = offchainTxs.sorted{ $0.sortDate > $1.sortDate }
                completion((offchainTxs, nil))
                return
            }
            
            let lastHundred = rows.suffix(100)
            
            for (i, payment) in lastHundred.enumerated() {
                if payment[4] as! String == "paid" {
                    let date = date(unixStamp: payment[15] as! Int)
                    let dateString = dateString(date: date)
                    let amount = amounts(amountMsat: payment[14] as! Int)
                    
                    let offChainTx: OffchainTx = .init(
                        bolt11: payment[7] as? String ?? "",
                        bolt12: payment[8] as? String ?? "",
                        amount: amount,
                        status: payment[4] as! String,
                        type: "Received",
                        date: dateString,
                        description: payment[2] as? String ?? "",
                        sortDate: date
                    )
                    
                    offchainTxs.append(offChainTx)
                }
                if i + 1 == lastHundred.count {
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
