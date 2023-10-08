//
//  FiatConverter.swift
//  BitSense
//
//  Created by Peter on 26/09/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import Foundation

class FiatConverter {
    static let sharedInstance = FiatConverter()
    private init() {}
    
    func getFxRate(completion: @escaping ((Double?)) -> Void) {
        let currency = UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
        let torClient = URLSession(configuration: .default)
        let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
        if useBlockchainInfo {
            let url = NSURL(string: "https://blockchain.info/ticker")
            let task = torClient.dataTask(with: url! as URL) { (data, response, error) -> Void in
                guard let urlContent = data,
                      let json = try? JSONSerialization.jsonObject(with: urlContent, options: [.mutableContainers]) as? [String : Any],
                      let data = json["\(currency)"] as? NSDictionary,
                      let rateCheck = data["15m"] as? Double else {
                    completion(nil)
                    return
                }
                UserDefaults.standard.set(rateCheck, forKey: "fxRate")
                completion(rateCheck)
            }
            task.resume()
        } else {
            let url = NSURL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")
            let task = torClient.dataTask(with: url! as URL) { (data, response, error) -> Void in
                guard let urlContent = data,
                    let json = try? JSONSerialization.jsonObject(with: urlContent, options: [.mutableContainers]) as? [String : Any],
                    let dict = json["bpi"] as? NSDictionary,
                    let usd = dict["\(currency)"] as? NSDictionary,
                    let price = usd["rate_float"] as? Double else {
                        completion(nil)
                        return
                }
                UserDefaults.standard.set(price, forKey: "fxRate")
                completion(price.rounded())
            }
            task.resume()
        }
    }
    
    func getOriginRate(date: String, completion: @escaping ((Double?)) -> Void) {
        let torClient = URLSession(configuration: .default)
        let url = NSURL(string: "https://api.coindesk.com/v1/bpi/historical/close.json?start=\(date)&end=\(date)")
        let task = torClient.dataTask(with: url! as URL) { (data, response, error) -> Void in
            guard let urlContent = data,
                let json = try? JSONSerialization.jsonObject(with: urlContent, options: [.mutableContainers]) as? [String : Any],
                let dict = json["bpi"] as? NSDictionary,
                let price = dict["\(date)"] as? Double else {
                    completion(nil)
                    return
            }
            completion(price)
        }
        task.resume()
    }
}
