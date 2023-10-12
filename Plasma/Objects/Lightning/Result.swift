//
//  Result.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/8/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import Foundation

public struct ResultObject: CustomStringConvertible {
    let result: [String: Any]?
    let error: [String: Any]?
    let message: String?
        
    init(data: Data) {
        guard let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else {
            result = nil
            error = nil
            message = "Unable to decode data."
            return
        }
        result = response["result"] as? [String: Any]
        error = response["error"] as? [String: Any]
        message = error?["message"] as? String
    }
    
    public var description: String {
        return "Result from Core Lighnting rpc command."
    }
    
}
