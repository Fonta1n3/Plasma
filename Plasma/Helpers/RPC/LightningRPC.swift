//
//  LightningRPC.swift
//  FullyNoded
//
//  Created by Peter on 02/08/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import Foundation


class LightningRPC {
    
    static let sharedInstance = LightningRPC()
    var ln: LNSocket?
    let default_timeout: Int32 = 8000
    
    
    private init() {
        ln = LNSocket()
    }
      
    
    func command(method: LIGHTNING_CLI, params: [String: String], completion: @escaping ((response: Any?, errorDesc: String?)) -> Void) {
        #if DEBUG
        print("method: \(method.rawValue), params: \(params)")
        #endif
        
        CoreDataService.retrieveEntity(entityName: .nodes) { [weak self] nodes in
            guard let self = self else { return }

            guard let (rune, id, address, port) = decryptedNodeCreds(nodes: nodes) else {
                completion((nil, "Error decrypting node creds."))
                return
            }
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { return }
                
                guard let ln = ln else {
                    completion((nil, "LNSocket is nil."))
                    return
                }
                
                guard ln.connect_and_init(node_id: id, host: "\(address):\(port)") else {
                    completion((nil, "Could not connect to node."))
                    return
                }
                
                var msg:Data?
                
                if method == .decode {
                    msg = make_commando_msg(authToken: rune, operation: method.rawValue, params: [params["invoice"]])
                } else {
                    msg = make_commando_msg(authToken: rune, operation: method.rawValue, params: params)
                }
                
                guard let msg = msg else {
                    completion((nil, "Out of memory."))
                    return
                }
                
                guard ln.write(msg) else {
                    completion((nil, "Write failed."))
                    return
                }
                
                switch commando_read_all(ln: ln, timeout_ms: default_timeout) {
                case .failure(let req_err):
                    completion((nil, req_err.description))
                    return
                    
                case .success(let data):
                    parseResponseData(method: method, data: data, completion: completion)
                }
            }
        }
    }
    
    
    private func decryptedNodeCreds(nodes: [[String: Any]]?) -> (rune: String, id: String, address: String, port: String)? {
        guard let node = activeNode(nodes: nodes) else {
            return nil
        }
        
        guard let encRune = node.rune,
              let encId = node.nodeId,
              let encAddress = node.address else {
            return nil
        }
        
        guard let rune = decryptedValue(encRune),
              let id = decryptedValue(encId),
              let address = decryptedValue(encAddress) else {
            return nil
        }
        
        return (rune, id, address, node.port)
    }
    
    
    private func activeNode(nodes: [[String: Any]]?) -> NodeStruct? {
        guard let nodes = nodes else {
            return nil
        }
        
        var activeNode: [String:Any]?
        
        for node in nodes {
            let n = NodeStruct(dictionary: node)
            if n.isActive {
                activeNode = node
            }
        }
        
        guard let lightningNode = activeNode else {
            return nil
        }
        
        return NodeStruct(dictionary: lightningNode)
    }
    
    
    private func dec(_ codable: Codable.Type, _ jsonData: Data) -> (response: Any?, errorDesc: String?) {
        let decoder = JSONDecoder()
        do {
            let item = try decoder.decode(codable.self, from: jsonData)
            return((item, nil))
        } catch {
            return((nil, "\(error)"))
        }
    }
    
    
    private func parseResponseData(method: LIGHTNING_CLI, data: Data, completion: @escaping ((response: Any?, errorDesc: String?)) -> Void) {
        let resultObject = ResultObject(data: data)
        
        guard let result = resultObject.result else {
            completion((nil, resultObject.message ?? "Unknow error."))
            return
        }
        
        guard let jsonData = result.jsonData else {
            completion((nil, "Error serializing json result."))
            return
        }
        
        #if DEBUG
        print("jsonData: \(jsonData.utf8String!)")
        #endif
        
        switch method {
        case .getinfo:
            completion(dec(GetInfo.self, jsonData))
            
        case .listfunds:
            completion(dec(ListFunds.self, jsonData))
            
        case .offer:
            completion(dec(Offer.self, jsonData))
            
        case .invoice:
            completion((dec(Invoice.self, jsonData)))
            
        case .listconfigs:
            completion((dec(ListConfigs.self, jsonData)))
            
        case .listpeerchannels:
            completion((dec(ListPeerChannels.self, jsonData)))
            
        case .listinvoices:
            completion((dec(ListInvoices.self, jsonData)))
            
        case .listsendpays:
            completion((dec(ListSendPays.self, jsonData)))
            
        case .withdraw:
            completion((dec(Withdraw.self, jsonData)))
            
        case .fetchinvoice:
            completion((dec(FetchInvoice.self, jsonData)))
            
        case .decode:
            completion((dec(DecodedInvoice.self, jsonData)))
            
        case .pay:
            completion((dec(Pay.self, jsonData)))
            
        case .newaddr:
            completion((dec(NewAddr.self, jsonData)))
            
        default:
            completion((result, nil))
            return
        }
        return
    }
}
