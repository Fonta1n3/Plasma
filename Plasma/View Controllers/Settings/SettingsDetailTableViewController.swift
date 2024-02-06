//
//  SettingsDetailTableViewController.swift
//  Plasma
//
//  Created by Peter Denton on 12/28/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import UIKit

class SettingsDetailTableViewController: UITableViewController {
    
    var showDenominations = false
    var showApis = false
    var showCurrencies = false
    
    @IBOutlet var settingDetail: UITableView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        if showDenominations {
            self.title = "Denomination"
        } else if showApis {
            self.title = "FX Rate API"
        } else if showCurrencies {
            self.title = "Fiat Currency"
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        impact()
        
        if showDenominations {
            UserDefaults.standard.setValue(denominations[indexPath.row], forKey: "denomination")
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                settingDetail.reloadData()
            }
        }
        
        if showApis {
            switch indexPath.row {
            case 0: UserDefaults.standard.setValue(true, forKey: "useBlockchainInfo")
            case 1: UserDefaults.standard.setValue(false, forKey: "useBlockchainInfo")
            default:
                break
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                settingDetail.reloadData()
            }
        }
        
        if showCurrencies {
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
                    
                    settingDetail.reloadData()
                }
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if showDenominations {
            return denominations.count
        } else if showApis {
            return 2
        } else if showCurrencies {
            let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
            if useBlockchainInfo {
                return blockchainInfoCurrencies.count
            } else {
                return coindeskCurrencies.count
            }
        } else {
            return 0
        }
    }
    
    
    private func configureCell(_ cell: UITableViewCell) {
        cell.selectionStyle = .none
    }
    
    
    func exchangeRateApiCell(_ indexPath: IndexPath) -> UITableViewCell {
        let exchangeRateApiCell = settingDetail.dequeueReusableCell(withIdentifier: "checkmarkCell", for: indexPath)
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
        let currencyCell = settingDetail.dequeueReusableCell(withIdentifier: "checkmarkCell", for: indexPath)
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
        let denominationCell = settingDetail.dequeueReusableCell(withIdentifier: "checkmarkCell", for: indexPath)
        configureCell(denominationCell)
        
        let label = denominationCell.viewWithTag(1) as! UILabel
        label.adjustsFontSizeToFitWidth = true
                
        let icon = denominationCell.viewWithTag(3) as! UIImageView
        
        let denomination = UserDefaults.standard.object(forKey: "denomination") as? String ?? "BTC"
        
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

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showDenominations {
            
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
            
        } else if showApis {
            
            return exchangeRateApiCell(indexPath)
            
        } else if showCurrencies {
            let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
            
            var currencies:[[String:String]] = blockchainInfoCurrencies
            
            if !useBlockchainInfo {
                currencies = coindeskCurrencies
            }
            
            return currencyCell(indexPath, currencies[indexPath.row])
        } else {
            return UITableViewCell()
        }
    }

}
