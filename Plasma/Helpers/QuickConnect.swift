//
//  QuickConnect.swift
//  BitSense
//
//  Created by Peter on 28/10/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import Foundation

class QuickConnect {
    
    // MARK: QuickConnect uri examples
    /// lnlink:02b10ff0fad12abf6e96730afb98bdbffc8d9ec11af8e7a1cb35ac48a54257a018@127.0.0.1:7171?token=59FSVv_QDQ_kLqZsWiJ9csyYsk0HR-KffUgjyqXkmTY9MA%3D%3D
        
    class func addNode(urlString: String, completion: @escaping ((node: NodeStruct?, errorMessage: String?)) -> Void) {
        
        func get_qs_param(qs: URLComponents, param: String) -> String? {
            return qs.queryItems?.first(where: { $0.name == param })?.value
        }
        
        var auth_qr = urlString
        if auth_qr.hasPrefix("lnlink:") && !auth_qr.hasPrefix("lnlink://") {
            auth_qr = urlString.replacingOccurrences(of: "lnlink:", with: "lnlink://")
        }
        
        guard let url = URL(string: auth_qr) else {
            completion((nil, "Invalid url."))
            return
        }
        
        guard let nodeid = url.user else {
            completion((nil, "No nodeid found in auth qr."))
            return
        }
        
        guard var host = url.host else {
            completion((nil, "No host found in auth qr."))
            return
        }
        
        let port = url.port ?? 9735
        
        guard let qs = URLComponents(string: auth_qr) else {
            completion((nil, "Invalid url querystring"))
            return
        }
        
        guard let token = get_qs_param(qs: qs, param: "token") else {
            completion((nil, "No token found in auth qr"))
            return
        }
        
        var newNode:[String:Any] = [:]
        newNode["id"] = UUID()
        newNode["label"] = "CLN Node"
        newNode["nodeId"] = nodeid.utf8
        newNode["address"] = host.utf8
        newNode["port"] = "\(port)"
        newNode["rune"] = token.utf8
        newNode["isActive"] = true
        
        completion((NodeStruct(dictionary: newNode), nil))
        
        
//        CoreDataService.retrieveEntity(entityName: .nodes) { (nodes) in
//            guard let nodes = nodes, nodes.count > 0 else { saveNode(newNode, completion: completion); return }
//
//            for (i, existingNode) in nodes.enumerated() {
//                let existingNodeStruct = NodeStruct(dictionary: existingNode)
//                if let existingNodeId = existingNodeStruct.id {
//                    if existingNodeStruct.isActive {
//                        CoreDataService.update(id: existingNodeId, keyToUpdate: "isActive", newValue: false, entity: .nodes) { _ in }
//                    }
//                }
//                if i + 1 == nodes.count {
//                    saveNode(newNode, completion: completion)
//                }
//            }
//        }
    }

    
//    private class func saveNode(_ node: [String:Any], completion: @escaping ((success: Bool, errorMessage: String?)) -> Void) {
//        CoreDataService.saveEntity(dict: node, entityName: .nodes) { success in
//            if success {
//                completion((true, nil))
//            } else {
//                completion((false, "Error saving your node."))
//            }
//        }
//    }
    
}
