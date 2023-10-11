//
//  ActiveWalletViewController.swift
//  BitSense
//
//  Created by Peter on 15/06/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import UIKit

class ActiveWalletViewController: UIViewController {
    
    var balances: Balances? = nil
    var onchainTxs: [Output]? = nil
    var showOnchain = false
    var showOffchain = false
    var fxRate: Double?
    private var offchainTxs: OffchainTxs = []
    private var dataRefresher = UIBarButtonItem()
    private let spinner = ConnectingView()
    
    @IBOutlet weak private var backgroundView: UIVisualEffectView!
    @IBOutlet weak private var walletTable: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletTable.delegate = self
        walletTable.dataSource = self
        spinner.addConnectingView(vc: self, description: "")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        loadTable()
    }
    
    
   private func loadTable() {
       if showOffchain {
           navigationItem.title = "Payments"
           loadTransactions()
       } else  if showOnchain {
           navigationItem.title = "UTXO's"
           finishedLoading()
       }
    }
        
    
    private func finishedLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.walletTable.reloadSections(.init(arrayLiteral: 0), with: .fade)
            self.removeSpinner()
        }
    }
        
    
    private func offchainTransactionsCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = walletTable.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
        cell.selectionStyle = .none
        let amountLabel = cell.viewWithTag(2) as! UILabel
        let confirmationsLabel = cell.viewWithTag(3) as! UILabel
        let dateLabel = cell.viewWithTag(5) as! UILabel
        let memoLabel = cell.viewWithTag(10) as! UILabel
        let index = indexPath.row
        let offchainTx = offchainTxs[index]
        amountLabel.text = offchainTx.amount
        confirmationsLabel.text = offchainTx.type
        
        if offchainTx.type.contains("Received") {
            amountLabel.textColor = .none
            
        } else if offchainTx.type.contains("Sent") {
            amountLabel.textColor = .secondaryLabel
        }
        
        dateLabel.text = offchainTx.date
        memoLabel.text = offchainTx.description
        
        if memoLabel.text == "" {
            memoLabel.text = "No description."
        }
        
        return cell
    }
    
    
    private func onchainTransactionsCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = walletTable.dequeueReusableCell(withIdentifier: "OnchainCell", for: indexPath)
        cell.selectionStyle = .none
        
        let amountLabel = cell.viewWithTag(2) as! UILabel
        let confirmationsLabel = cell.viewWithTag(3) as! UILabel
        let dateLabel = cell.viewWithTag(5) as! UILabel
        
        if let tx = onchainTxs?[indexPath.row] {
            let amountDict:[String:Any] = ["onchainMsatBalance": tx.amountMsat]
            let balance = Balances(dictionary: amountDict)
            amountLabel.text = balance.onchainBalance
            confirmationsLabel.text = tx.status
            if tx.status == "unconfirmed" {
                amountLabel.textColor = .quaternaryLabel
            } else {
                amountLabel.textColor = .none
            }
            
            if let block = tx.blockheight {
                dateLabel.text = "Block \(block)"
            } else {
                dateLabel.text = "Pending..."
            }
            
        }
        return cell
    }
       
    
    private func blankCell() -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        if showOffchain {
            cell.textLabel?.text = "No payments yet."
        } else {
            cell.textLabel?.text = "No utxo's yet."
        }
        return cell
    }
      
    
    func reloadWalletData() {
        offchainTxs.removeAll()
    }
    
    
    private func loadTransactions() {
        offchainTxs.removeAll()
        
        FetchFunds.sharedInstance.getCLTransactions { [weak self] (response, errorMessage) in
            guard let self = self else { return }
            
            guard let response = response else {
                self.removeSpinner()
                
                guard let errorMessage = errorMessage else {
                    return
                }
                showAlert(vc: self, title: "", message: errorMessage)
                return
            }
            
            offchainTxs = response
            if offchainTxs.count == 0 {
                showAlert(vc: self, title: "", message: "No lightning payments made yet.")
            }
            finishedLoading()
        }
    }
    
    
    private func removeSpinner() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            spinner.removeConnectingView()
        }
    }
    
    
    private func reloadTable() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.walletTable.reloadData()
        }
    }
}

extension ActiveWalletViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showOnchain {
            guard let onchainTxs = onchainTxs, onchainTxs.count > 0 else { return blankCell() }
            
            return onchainTransactionsCell(indexPath)
            
        } else if showOffchain {
            if offchainTxs.count > 0 {
                return offchainTransactionsCell(indexPath)
            } else {
                return blankCell()
            }
        } else {
            return blankCell()
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if showOffchain && offchainTxs.count > 0 {
            return 145
        } else {
            return 90
        }
    }
}


extension ActiveWalletViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showOnchain {
            guard let onchainTxs = onchainTxs else { return 0 }
            
            return onchainTxs.count
            
        } else if showOffchain {
            return offchainTxs.count
        } else {
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
