//
//  SettingsViewController.swift
//  BitSense
//
//  Created by Peter on 08/10/18.
//  Copyright © 2018 Fontaine. All rights reserved.
//

import UIKit
import Foundation

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    let ud = UserDefaults.standard
    let spinner = ConnectingView()
    @IBOutlet weak var settingsTable: UITableView!
    
    private let blockchainInfoCurrencies:[[String:String]] = [
        ["USD": "dollarsign.circle"],
        ["GBP": "sterlingsign.circle"],
        ["EUR": "eurosign.circle"],
        ["AUD":"dollarsign.circle"],
        ["BRL": "brazilianrealsign.circle"],
        ["CAD": "dollarsign.circle"],
        ["CHF": "francsign.circle"],
        ["CLP": "dollarsign.circle"],
        ["CNY": "yensign.circle"],
        ["DKK": "k.circle"],
        ["HKD": "dollarsign.circle"],
        ["INR": "indianrupeesign.circle"],
        ["ISK": "k.circle"],
        ["JPY": "yensign.circle"],
        ["KRW": "wonsign.circle"],
        ["NZD": "dollarsign.circle"],
        ["PLN": "z.circle"],
        ["RUB": "rublesign.circle"],
        ["SEK": "k.circle"],
        ["SGD": "dollarsign.circle"],
        ["THB": "bahtsign.circle"],
        ["TRY": "turkishlirasign.circle"],
        ["TWD": "dollarsign.circle"]
    ]
    
    private let coindeskCurrencies:[[String:String]] = [
        ["USD": "dollarsign.circle"],
        ["GBP": "sterlingsign.circle"],
        ["EUR": "eurosign.circle"]
    ]
    
    private let denominations:[String] = [
        "BTC",
        "SATS",
        UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTable.delegate = self
        
        if UserDefaults.standard.object(forKey: "useBlockchainInfo") == nil {
            UserDefaults.standard.set(true, forKey: "useBlockchainInfo")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        settingsTable.reloadData()
    }
    
    private func configureCell(_ cell: UITableViewCell) {
        cell.selectionStyle = .none
    }
    
    private func settingsCell(_ indexPath: IndexPath) -> UITableViewCell {
        let settingsCell = settingsTable.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        configureCell(settingsCell)
        
        let label = settingsCell.viewWithTag(1) as! UILabel
        label.adjustsFontSizeToFitWidth = true
        
        let icon = settingsCell.viewWithTag(3) as! UIImageView
        
        switch indexPath.section {
        case 0:
            label.text = "Node manager"
            icon.image = UIImage(systemName: "server.rack")
            
        case 1:
            label.text = "Security Center"
            icon.image = UIImage(systemName: "lock.shield")
            
        default:
            break
        }
        
        return settingsCell
    }
    
    
    func exchangeRateApiCell(_ indexPath: IndexPath) -> UITableViewCell {
        let exchangeRateApiCell = settingsTable.dequeueReusableCell(withIdentifier: "checkmarkCell", for: indexPath)
        configureCell(exchangeRateApiCell)
        
        let label = exchangeRateApiCell.viewWithTag(1) as! UILabel
        label.adjustsFontSizeToFitWidth = true
        
        let icon = exchangeRateApiCell.viewWithTag(3) as! UIImageView
        
        let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
        
        icon.image = UIImage(systemName: "server.rack")
        
        switch indexPath.row {
        case 0:
            label.text = "Blockchain.info"
            if useBlockchainInfo {
                //background.backgroundColor = .systemBlue
                exchangeRateApiCell.isSelected = true
                exchangeRateApiCell.accessoryType = .checkmark
            } else {
                //background.backgroundColor = .systemGray
                exchangeRateApiCell.isSelected = false
                exchangeRateApiCell.accessoryType = .none
            }
        case 1:
            label.text = "Coindesk"
            if !useBlockchainInfo {
                //background.backgroundColor = .systemBlue
                exchangeRateApiCell.isSelected = true
                exchangeRateApiCell.accessoryType = .checkmark
            } else {
                //background.backgroundColor = .systemGray
                exchangeRateApiCell.isSelected = false
                exchangeRateApiCell.accessoryType = .none
            }
        default:
            break
        }
        
        return exchangeRateApiCell
    }
    
    func currencyCell(_ indexPath: IndexPath, _ currency: [String:String]) -> UITableViewCell {
        let currencyCell = settingsTable.dequeueReusableCell(withIdentifier: "checkmarkCell", for: indexPath)
        configureCell(currencyCell)
        
        let label = currencyCell.viewWithTag(1) as! UILabel
        label.adjustsFontSizeToFitWidth = true
                
        let icon = currencyCell.viewWithTag(3) as! UIImageView
        
        let currencyToUse = UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
        
        for (key, value) in currency {
            if currencyToUse == key {
                currencyCell.accessoryType = .checkmark
                currencyCell.isSelected = true
            } else {
                currencyCell.accessoryType = .none
                currencyCell.isSelected = false
            }
            label.text = key
            icon.image = UIImage(systemName: value)
        }
        
        return currencyCell
    }
    
    private func denominationCell(_ indexPath: IndexPath, _ currency: [String:String]) -> UITableViewCell {
        let denominationCell = settingsTable.dequeueReusableCell(withIdentifier: "checkmarkCell", for: indexPath)
        configureCell(denominationCell)
        
        let label = denominationCell.viewWithTag(1) as! UILabel
        label.adjustsFontSizeToFitWidth = true
                
        let icon = denominationCell.viewWithTag(3) as! UIImageView
        
        let denomination = UserDefaults.standard.object(forKey: "denomination") as? String ?? "BTC"
        print("denomination: \(denomination)")
        
        if denomination == denominations[indexPath.row] {
            denominationCell.accessoryType = .checkmark
            denominationCell.isSelected = true
        } else {
            denominationCell.accessoryType = .none
            denominationCell.isSelected = false
        }
        
        switch indexPath.row {
        case 0:
            label.text = "BTC"
            icon.image = UIImage(systemName: "bitcoinsign.circle")
        case 1:
            label.text = "SATS"
            icon.image = UIImage(systemName: "s.circle")
        case 2:
            label.text = UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
            for (_, value) in currency {
                icon.image = UIImage(systemName: value)
            }
        default:
            break
        }
        
        return denominationCell
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0, 1:
            return settingsCell(indexPath)
            
        case 2:
            let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
            
            var currencies:[[String:String]] = blockchainInfoCurrencies
            
            if !useBlockchainInfo {
                currencies = coindeskCurrencies
            }
            
            var fiat:[String:String] = [:]
            for currency in currencies {
                for (key, _) in currency {
                    if key == UserDefaults.standard.object(forKey: "currency") as? String ?? "USD" {
                        fiat = currency
                    }
                }
            }
            
            return denominationCell(indexPath, fiat)
            
        case 3:
            return exchangeRateApiCell(indexPath)
            
        case 4:
            let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
            
            var currencies:[[String:String]] = blockchainInfoCurrencies
            
            if !useBlockchainInfo {
                currencies = coindeskCurrencies
            }
            
            return currencyCell(indexPath, currencies[indexPath.row])
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 50)
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textLabel.textColor = .secondaryLabel
        textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 50)
        switch section {
        case 0:
            textLabel.text = "Nodes"
                        
        case 1:
            textLabel.text = "Security"
            
        case 2:
            textLabel.text = "Denomination"
            
        case 3:
            textLabel.text = "Exchange Rate API"
            
        case 4:
            textLabel.text = "Fiat Currency"
            
        default:
            break
        }
        
        header.addSubview(textLabel)
        return header
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 2: return 3
        case 3: return 2
        case 4:
            let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
            if useBlockchainInfo {
                return blockchainInfoCurrencies.count
            } else {
                return coindeskCurrencies.count
            }
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        impact()
        
        switch indexPath.section {
        case 0:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.performSegue(withIdentifier: "goToNodes", sender: self)
            }
            
        case 1:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.performSegue(withIdentifier: "goToSecurity", sender: self)
            }
            
        
            
        case 2:
            UserDefaults.standard.setValue(denominations[indexPath.row], forKey: "denomination")
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.settingsTable.reloadSections(.init(arrayLiteral: 2), with: .none)
            }
            
        case 3:
            switch indexPath.row {
            case 0: UserDefaults.standard.setValue(true, forKey: "useBlockchainInfo")
            case 1: UserDefaults.standard.setValue(false, forKey: "useBlockchainInfo")
            default:
                break
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.settingsTable.reloadSections(.init(arrayLiteral: 3, 4), with: .none)
            }
            
        case 4:
            let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
            var currencies:[[String:String]] = []
            if useBlockchainInfo {
                currencies = blockchainInfoCurrencies
            } else {
                currencies = coindeskCurrencies
            }
            let currencyDict = currencies[indexPath.row]
            for (key, _) in currencyDict {
                UserDefaults.standard.setValue(key, forKey: "currency")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    self.settingsTable.reloadSections(.init(arrayLiteral: 4, 2), with: .none)
                }
            }
            
        default:
            break
            
        }
    }
}



