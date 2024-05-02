//
//  LightningNodeManagerViewController.swift
//  FullyNoded
//
//  Created by Peter on 05/08/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import UIKit


class NodeInfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate {
    
    var uri = ""
    var tableArray = [String]()
    var spinner = ConnectingView()
    var info: GetInfo?
    
    @IBOutlet var nodeTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nodeTable.delegate = self
        nodeTable.dataSource = self
        addSpinner()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        clightningGetInfo()
    }
    
    
    private func removeSpinner() {
        spinner.removeConnectingView()
    }
    
    
    private func addSpinner() {
        spinner.addConnectingView(vc: self, description: "getting info...")
    }
    
    
    @IBAction func shareNodeUrlAction(_ sender: Any) {
        if let info = info {
            let id = info.id
            if info.address.count > 0 {
                let addr = info.address[0].address
                let port = info.address[0].port
                uri = id + "@" + addr + ":" + "\(port)"
                
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.performSegue(withIdentifier: "segueToShareLightningUrl", sender: vc)
                }
            } else {
                showAlert(vc: self, title: "", message: "No address specified in your lightning config.")
            }
        }
    }
    
    
    private func clightningGetInfo() {
        LightningRPC.sharedInstance.command(method: .getinfo, params: [:]) { [weak self] (info, errorDesc) in
            guard let self = self else { return }
            guard let info = info as? GetInfo else {
                self.removeSpinner()
                showAlert(vc: self, title: "Error", message: errorDesc ?? "error getting info from lightning node")
                return
            }
            
            self.info = info
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                nodeTable.reloadSections(.init(arrayLiteral: 0), with: .fade)
            }
            listFunds()
        }
    }
    
    
    private func listFunds() {
        FetchFunds.sharedInstance.balancesAndTxs { [weak self] (balances, txs, errorMessage) in
            guard let self = self else { return }
            
            guard let balances = balances else {
                showAlert(vc: self, title: "", message: errorMessage ?? "Unknown error listfunds.")
                return
            }
                        
            tableArray.append(balances.onchainBalance)
            tableArray.append(balances.offchainBalance)
            
            getSpendableReceivable()
        }
    }
    
    
    private func getSpendableReceivable() {
        var totalSpendable = 0
        var totalReceivable = 0
        
        LightningRPC.sharedInstance.command(method: .listpeerchannels, params: [:]) { [weak self] (listPeerChannels, errorDesc) in
            guard let self = self else { return }
            
            guard let listPeerChannels = listPeerChannels as? ListPeerChannels else {
                finishedLoading()
                return
            }
            
            let channels = listPeerChannels.channels
            
            guard channels.count > 0 else {
                tableArray.append("0")
                tableArray.append("0")
                finishedLoading()
                return
            }
                        
            for (i, channel) in channels.enumerated() {
                
                totalSpendable += channel.spendableMsat ?? 0
                totalReceivable += channel.receivableMsat ?? 0
                
                if i + 1 == channels.count {
                    let spendDict:[String:Any] = ["offchainMsatBalance": totalSpendable]
                    let recDict:[String:Any] = ["offchainMsatBalance": totalReceivable]
                    let spendBalance = Balances(dictionary: spendDict)
                    let recBalance = Balances(dictionary: recDict)
                    tableArray.append(spendBalance.offchainBalance)
                    tableArray.append(recBalance.offchainBalance)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        nodeTable.reloadSections(.init(arrayLiteral: 1), with: .fade)
                        removeSpinner()
                    }
                }
            }
        }
    }
    
    
    private func finishedLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.nodeTable.reloadData()
            self.removeSpinner()
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if let _ = info {
                return 17
            } else {
                return 0
            }
        case 1:
            if tableArray.count > 0 {
                return 4
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "lightningCell", for: indexPath)
        cell.selectionStyle = .none
        //let icon = cell.viewWithTag(2) as! UIImageView
        let headerLabel = cell.viewWithTag(2) as! UILabel
        let label = cell.viewWithTag(3) as! UILabel
        if let info = info {
            switch indexPath.section {
            case 0:
                label.text = ""
                switch indexPath.row {
                case 0:
                    //icon.image = UIImage(systemName: "person")
                    headerLabel.text = "Alias"
                    label.text = info.alias
                    
                case 1:
                    //icon.image = UIImage(systemName: "person.3")
                    headerLabel.text = "Peers"
                    label.text = "\(info.numPeers)"
                    
                case 2:
                    //icon.image = UIImage(systemName: "slider.horizontal.3")
                    headerLabel.text = "Active channels"
                    label.text = "\(info.numActiveChannels)"
                    
                case 3:
                    //icon.image = UIImage(systemName: "moon.zzz")
                    headerLabel.text = "Inactive channels"
                    label.text = "\(info.numInactiveChannels)"
                    
                case 4:
                    //icon.image = UIImage(systemName: "hourglass")
                    headerLabel.text = "Pending channels"
                    label.text = "\(info.numPendingChannels)"
                    
                case 5:
                    //icon.image = UIImage(systemName: "bitcoinsign.circle")
                    headerLabel.text = "Fees collected"
                    label.text = "\(info.feesCollectedMsat)"
                    
                case 6:
                    //icon.image = UIImage(systemName: "v.circle")
                    headerLabel.text = "Version"
                    label.text = info.version
                    
                case 7:
                    headerLabel.text = "Node ID"
                    label.text = info.id
                    
                case 8:
                    headerLabel.text = "Color"
                    label.text = info.color
                    
                case 9:
                    headerLabel.text = "Addresses"
                    var text = ""
                    for address in info.address {
                        text += "Address: " + address.address + "\n"
                        text += "Port: \(address.port)" + "\n"
                        text += "Type: " + address.type
                    }
                    label.text = text
                    
                case 10:
                    headerLabel.text = "Binding"
                    var text = ""
                    for address in info.binding {
                        text += "Address: " + address.address + "\n"
                        text += "Port: \(address.port)" + "\n"
                        text += "Type: " + address.type
                    }
                    label.text = text
                    
                case 11:
                    headerLabel.text = "Directory"
                    label.text = info.lightningDir
                    
                case 12:
                    headerLabel.text = "Network"
                    label.text = info.network
                    
                case 13:
                    headerLabel.text = "Blockheight"
                    label.text = "\(info.blockheight)"
                    
                case 14:
                    headerLabel.text = "Features node"
                    label.text = info.ourFeatures.node
                    
                case 15:
                    headerLabel.text = "Features channel"
                    label.text = info.ourFeatures.channel
                    
                case 16:
                    headerLabel.text = "Features invoice"
                    label.text = info.ourFeatures.invoice
                    
                default:
                    break
                }
                
                label.sizeToFit()
                
            case 1:
                switch indexPath.row {
                case 0:
                    //icon.image = UIImage(systemName: "link")
                    headerLabel.text = "Onchain wallet"
                    label.text = tableArray[0]
                    
                case 1:
                    //icon.image = UIImage(systemName: "bolt")
                    headerLabel.text = "Our channel funds"
                    label.text = tableArray[1]
                    
                case 2:
                    //icon.image = UIImage(systemName: "arrow.up.right")
                    headerLabel.text = "Total spendable"
                    label.text = tableArray[2]
                    
                case 3:
                    //icon.image = UIImage(systemName: "arrow.down.left")
                    headerLabel.text = "Total receivable"
                    label.text = tableArray[3]
                    
                default:
                    break
                }
                
            default:
                break
            }
        }
        //label.numberOfLines = 0
        //label.lineBreakMode = .byWordWrapping
        
//        cell.translatesAutoresizingMaskIntoConstraints = true
//        cell.sizeToFit()
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 50)
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 50)
        switch section {
        case 0:
            textLabel.text = "Info"
            
        case 1:
            textLabel.text = "Funds"
        
        default:
            break
        }
        header.addSubview(textLabel)
        return header
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 54
//    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToShareLightningUrl" {
            guard let vc = segue.destination as? QRDisplayerViewController else { return }
            
            vc.headerText = info!.alias
            vc.text = uri
        }
    }
}

