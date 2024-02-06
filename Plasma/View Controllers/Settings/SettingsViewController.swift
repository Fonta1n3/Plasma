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
    
    var denominations = false
    var apis = false
    var currencies = false
    let ud = UserDefaults.standard
    let spinner = ConnectingView()
    @IBOutlet weak var settingsTable: UITableView!
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTable.delegate = self
        
        if UserDefaults.standard.object(forKey: "useBlockchainInfo") == nil {
            UserDefaults.standard.set(true, forKey: "useBlockchainInfo")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        denominations = false
        apis = false
        currencies = false
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
            
        case 2:
            let denomination = UserDefaults.standard.object(forKey: "denomination") as? String ?? "BTC"
            
            label.text = denomination
            
            switch denomination {
            case "BTC":
                label.text = "BTC"
                icon.image = UIImage(systemName: "bitcoinsign.circle")
            case "SATS":
                label.text = "SATS"
                icon.image = UIImage(systemName: "s.circle")
            default:
                let currency = UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
                label.text = currency
    
            }
            
        case 3:
            let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
            
            icon.image = UIImage(systemName: "server.rack")
            
            if useBlockchainInfo {
                label.text = "Blockchain.info"
            } else {
                label.text = "Coindesk"
            }
            
        case 4:
            let currency = UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
            label.text = currency
            
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
            
            for (_, value) in fiat {
                icon.image = UIImage(systemName: value)
            }
            
        default:
            break
        }
        
        return settingsCell
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0, 1, 2, 3, 4:
            return settingsCell(indexPath)
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
        return 1
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
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                denominations = true
                performSegue(withIdentifier: "segueToSettingDetail", sender: self)
            }
            
            
            
        case 3:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                apis = true
                performSegue(withIdentifier: "segueToSettingDetail", sender: self)
            }
            
        case 4:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                currencies = true
                performSegue(withIdentifier: "segueToSettingDetail", sender: self)
            }
            
        default:
            break
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "segueToSettingDetail":
            guard let vc = segue.destination as? SettingsDetailTableViewController else { fallthrough }
            
            vc.showDenominations = denominations
            vc.showApis = apis
            vc.showCurrencies = currencies
        default:
            break
        }
    }
}



