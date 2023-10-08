//
//  NodeStruct.swift
//  BitSense
//
//  Created by Peter on 18/09/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import Foundation

public struct NodeStruct: CustomStringConvertible {
    
    let id: UUID?
    let label: String
    let isActive: Bool
    let address: Data?
    let rune: Data?
    let nodeId: Data?
    let port: String
    
    init(dictionary: [String: Any]) {
        id = dictionary["id"] as? UUID
        label = dictionary["label"] as? String ?? ""
        isActive = dictionary["isActive"] as? Bool ?? false
        address = dictionary["address"] as? Data
        rune = dictionary["rune"] as? Data
        nodeId = dictionary["nodeId"] as? Data
        port = dictionary["port"] as? String ?? "9735"
    }
    
    public var description: String {
        return ""
    }
    
}

