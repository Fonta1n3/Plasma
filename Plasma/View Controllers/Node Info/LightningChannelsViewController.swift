//
//  LightningChannelsViewController.swift
//  FullyNoded
//
//  Created by Peter on 17/08/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import UIKit

class LightningChannelsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var ours = [PeerChannel]()
    var theirs = [PeerChannel]()
    let spinner = ConnectingView()
    var activeChannels: [PeerChannel] = []
    var inactiveChannels: [PeerChannel] = []
    var pendingChannels: [PeerChannel] = []
    var selectedChannel:PeerChannel?
    var myId = ""
    var outgoingChannel:PeerChannel?
    var incomingChannel:PeerChannel?

    @IBOutlet weak var channelsTable: UITableView!
    @IBOutlet weak var totalReceivableLabel: UILabel!
    @IBOutlet weak var totalSpendableLabel: UILabel!
    @IBOutlet weak var oursIcon: UILabel!
    @IBOutlet weak var theirsIcon: UILabel!
    @IBOutlet weak var ourBalanceLabel: UILabel!
    @IBOutlet weak var theirBalanceLabel: UILabel!
    @IBOutlet weak var rebalanceOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        channelsTable.delegate = self
        channelsTable.dataSource = self
        channelsTable.clipsToBounds = true
        channelsTable.layer.cornerRadius = 8
        
        
        oursIcon.clipsToBounds = true
        oursIcon.layer.cornerRadius = oursIcon.frame.width / 2
        
        theirsIcon.clipsToBounds = true
        theirsIcon.layer.cornerRadius = theirsIcon.frame.width / 2
        
        totalReceivableLabel.text = ""
        totalSpendableLabel.text = ""
        spinner.addConnectingView(vc: self, description: "getting channels...")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        activeChannels.removeAll()
        inactiveChannels.removeAll()
        pendingChannels.removeAll()
        loadChannels()
    }
    
    
    @IBAction func addChannel(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: "segueToCreateChannel", sender: self)
        }
    }
    
    @IBAction func rebalanceAction(_ sender: Any) {
        showAlert(vc: self, title: "Rebalance Channels", message: "This action depends upon the rebalance.py plugin. If you have the plugin installed simply tap a channel to rebalance, this command can take a bit of time.")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if activeChannels.count > 0 {
                return activeChannels.count
            } else {
                return 1
            }
        case 1:
            if inactiveChannels.count > 0 {
                return inactiveChannels.count
            } else {
                return 1
            }
        case 2:
            if pendingChannels.count > 0 {
                return pendingChannels.count
            } else {
                return 1
            }
        default:
            return 0
        }
    }
    
    
    private func denomination() -> String {
        return UserDefaults.standard.object(forKey: "denomination") as? String ?? "BTC"
    }
    
    
    private func activeCell(_ indexPath: IndexPath, _ tableView: UITableView) -> UITableViewCell {
        if activeChannels.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "activeChannelCell", for: indexPath)
            cell.selectionStyle = .none
            let amountReceivableLabel = cell.viewWithTag(1) as! UILabel
            let amountSpendableLabel = cell.viewWithTag(2) as! UILabel
            let bar = cell.viewWithTag(3) as! UIProgressView
            let headerLabel = cell.viewWithTag(4) as! UILabel
            
            let channel = activeChannels[indexPath.row]
            headerLabel.text = "ID: \(channel.shortChannelID)"
            
            switch denomination() {
            case "BTC":
                amountSpendableLabel.text = Double(channel.spendableMsat.msatToBtc)!.btcBalanceWithSpaces
                amountReceivableLabel.text  = Double(channel.receivableMsat.msatToBtc)!.btcBalanceWithSpaces
                
            case "SATS":
                amountSpendableLabel.text = channel.spendableMsat.msatToSat
                amountReceivableLabel.text  = channel.receivableMsat.msatToSat
                
            default:
                amountSpendableLabel.text = channel.spendableMsat.msatToFiat!
                amountReceivableLabel.text  = channel.receivableMsat.msatToFiat!
            }
            
            let ratio = Double(channel.toUsMsat) / Double(channel.totalMsat)
            bar.setProgress(Float(ratio), animated: true)
            return cell
        } else {
            let blankCell = UITableViewCell()
            blankCell.textLabel?.text = "No active channels."
            return blankCell
        }
        
    }
    
    
    private func pendingCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        if pendingChannels.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath)
            cell.selectionStyle = .none
            let channel = pendingChannels[indexPath.row]
            cell.textLabel?.text = channel.channelID
            return cell
        } else {
            let blankCell = UITableViewCell()
            blankCell.textLabel?.text = "No pending channels."
            return blankCell
        }
    }
    
    
    private func inactiveCell(_ indexPath: IndexPath, _ tableView: UITableView) -> UITableViewCell {
        if inactiveChannels.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath)
            cell.selectionStyle = .none
            let channel = inactiveChannels[indexPath.row]
            cell.textLabel?.text = channel.channelID
            return cell
        } else {
            let blankCell = UITableViewCell()
            blankCell.textLabel?.text = "No inactive channels."
            return blankCell
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return activeCell(indexPath, tableView)
        case 1:
            return inactiveCell(indexPath, tableView)
        case 2:
            return pendingCell(indexPath, tableView: tableView)
        default:
            return UITableViewCell()
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            if activeChannels.count > 0 {
                return 122
            } else {
                return 44
            }
        case 1:
            return 44
        default:
            return 44
        }
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 50)
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        textLabel.textColor = .lightGray
        textLabel.frame = CGRect(x: 0, y: 0, width: view.frame.width - 32, height: 50)
        
        switch section {
        case 0:
            textLabel.text = "Active Channels"
            
        case 1:
            textLabel.text = "Inactive Channels"
            
        case 2:
            textLabel.text = "Pending Channels"
            
        default:
            break
        }
        
        header.addSubview(textLabel)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard activeChannels.count > 1 else {
            showAlert(vc: self, title: "You need more then 1 channel to rebalance.", message: "")
            return
        }
        
        selectedChannel = activeChannels[indexPath.section]
        promptToRebalanceCL()
    }
    
//    @objc func closeChannel(_ sender: UIButton) {
//        promptToCloseChannel(channel: activeChannels[sender.tag])
//    }
    
//    private func promptToCloseChannel(channel: PeerChannel) {
//        DispatchQueue.main.async { [weak self] in
//            let alertStyle = UIAlertController.Style.alert
//
//            let alert = UIAlertController(title: "Close channel?", message: "This action will start the process of closing this channel.", preferredStyle: alertStyle)
//
//            alert.addAction(UIAlertAction(title: "Close", style: .destructive, handler: { [weak self] action in
//                guard let self = self else { return }
//
//                self.spinner.addConnectingView(vc: self, description: "closing...")
//                self.closeChannelCL(channel, nil)
//            }))
//
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
//            alert.popoverPresentationController?.sourceView = self?.view
//            self?.present(alert, animated: true, completion: nil)
//        }
//    }
    
//    private func promptToUseClosingAddress(_ address: String, _ channel: PeerChannel) {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//
//            let alertStyle = UIAlertController.Style.alert
//            let tit = "Automatically send your channel funds to \(address)?"
//            let mess = "Funds will automatically be sent to \(address) when the channel closes. This is NOT reversible!"
//
//            let alert = UIAlertController(title: tit, message: mess, preferredStyle: alertStyle)
//
//            alert.addAction(UIAlertAction(title: "Close to \(address)", style: .default, handler: { [weak self] action in
//                guard let self = self else { return }
//                self.spinner.addConnectingView(vc: self, description: "closing...")
//
//                self.closeChannelCL(channel, address)
//            }))
//
//            alert.addAction(UIAlertAction(title: "Use Lightning wallet", style: .default, handler: { [weak self] action in
//                guard let self = self else { return }
//                self.spinner.addConnectingView(vc: self, description: "closing...")
//
//                self.closeChannelCL(channel, nil)
//            }))
//
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
//            alert.popoverPresentationController?.sourceView = self.view
//            self.present(alert, animated: true, completion: nil)
//        }
//    }
        
//    private func closeChannelCL(_ channel: PeerChannel, _ address: String?) {
//        var param:[String:String] = [:]
//        param["id"] = channel.channelID
//        if let closingAddress = address {
//            param["destination"] = closingAddress
//        }
//
//        LightningRPC.sharedInstance.command(method: .close, params: param) { [weak self] (response, errorDesc) in
//            guard let self = self else { return }
//
//            self.spinner.removeConnectingView()
//
//            guard errorDesc == nil else {
//                showAlert(vc: self, title: "Error", message: errorDesc ?? "error disconnecting peer")
//                return
//            }
//
//            guard let response = response as? [String:Any] else {
//                showAlert(vc: self, title: "Error", message: errorDesc ?? "error disconnecting peer")
//                return
//            }
//
//            if let message = response["message"] as? String {
//                showAlert(vc: self, title: "Error disconnecting peer.", message: message)
//            } else {
//                showAlert(vc: self, title: "Channel disconnected ⚡️", message: "")
//                self.loadChannels()
//                return
//            }
//        }
//    }
            
//    private func saveTx(memo: String, hash: String, sats: Int) {
//        FiatConverter.sharedInstance.getFxRate { [weak self] fxRate in
//            guard let self = self else { return }
//
//            let fiatCurrency = UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
//
//            var dict:[String:Any] = ["txid":hash,
//                                     "id":UUID(),
//                                     "memo":memo,
//                                     "date":Date(),
//                                     "label":"Fully Noded Rebalance ⚡️",
//                                     "fiatCurrency": fiatCurrency]
//
//            self.spinner.removeConnectingView()
//
//            let tit = "Rebalance Success ⚡️"
//
//            guard let originRate = fxRate else {
//                CoreDataService.saveEntity(dict: dict, entityName: .transactions) { _ in }
//
//                showAlert(vc: self, title: tit, message: "\n\(sats) sats rebalanced.")
//                return
//            }
//
//            dict["originRate"] = originRate
//
//            let mess = "\n\(sats) sats / \((sats.satsToBtcDouble * originRate).balanceText) rebalanced."
//
//            showAlert(vc: self, title: tit, message: mess)
//
//            CoreDataService.saveEntity(dict: dict, entityName: .transactions) { _ in }
//        }
//    }
    
    
    private func loadChannels() {
        //spinner.addConnectingView(vc: self, description: "getting channels...")
        activeChannels.removeAll()
        inactiveChannels.removeAll()
        pendingChannels.removeAll()
        loadCLPeerChannels()
    }
    
    
    private func loadCLPeerChannels() {
        LightningRPC.sharedInstance.command(method: .listpeerchannels, params: [:]) { [weak self] (listPeerChannels, errorDesc) in
            guard let self = self else { return }
            
            guard let listPeerChannels = listPeerChannels as? ListPeerChannels else {
                self.spinner.removeConnectingView()
                showAlert(vc: self, title: "Error", message: errorDesc ?? "Unknown error fetching channels.")
                return
            }
            
            let channels = listPeerChannels.channels
            
            guard channels.count > 0 else {
                self.spinner.removeConnectingView()
                showAlert(vc: self, title: "No channels yet.", message: "Tap the + button to connect to a peer and start a channel.")
                return
            }
            
            self.parseCLChannels(channels)
        }
    }
            
    
    private func parseCLChannels(_ channels: [PeerChannel]) {
        var totalSpendable = 0
        var totalReceivable = 0
        
        for (i, channel) in channels.enumerated() {
            totalSpendable += channel.spendableMsat
            totalReceivable += channel.receivableMsat
            
            switch channel.state {
            case "CHANNELD_NORMAL":
                self.activeChannels.append(channel)
            case "CHANNELD_AWAITING_LOCKIN":
                self.pendingChannels.append(channel)
            default:
                self.inactiveChannels.append(channel)
            }
            
            if i + 1 == channels.count {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    switch denomination() {
                    case "BTC":
                        self.totalSpendableLabel.text = Double(totalSpendable.msatToBtc)!.btcBalanceWithSpaces
                        self.totalReceivableLabel.text = Double(totalReceivable.msatToBtc)!.btcBalanceWithSpaces
                        
                    case "SATS":
                        self.totalSpendableLabel.text = totalSpendable.msatToSat
                        self.totalReceivableLabel.text = totalReceivable.msatToSat
                        
                    default:
                        self.totalSpendableLabel.text = totalSpendable.msatToFiat
                        self.totalReceivableLabel.text = totalReceivable.msatToFiat
                    }
                }
                
                load()
            }
        }
    }
    
    private func load() {
        DispatchQueue.main.async { [weak self] in
            self?.channelsTable.reloadData()
            self?.spinner.removeConnectingView()
        }
    }
    
    private func showDetail() {
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: "segueToChannelDetails", sender: self)
        }
    }
    
    // MARK: - Rebalancing
            
    private func promptToRebalanceCL() {
        DispatchQueue.main.async { [weak self] in
            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            let alert = UIAlertController(title: "Send circular payment to rebalance?", message: "This action depends upon the rebalance.py plugin. It can take up to 60 seconds for this command to complete.", preferredStyle: alertStyle)
            alert.addAction(UIAlertAction(title: "Rebalance", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                self.spinner.addConnectingView(vc: self, description: "rebalancing, this can take up to 60 seconds...")
                self.parseChannelsForRebalancing()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self?.view
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    private func parseChannelsForRebalancing() {
        ours.removeAll()
        theirs.removeAll()
        
        for (i, ch) in activeChannels.enumerated() {
            let ratio = Double(ch.toUsMsat) / Double(ch.totalMsat)
            if ratio > 0.6 {
                ours.append(ch)
            } else if ratio < 0.4 {
                theirs.append(ch)
            }
            if i + 1 == activeChannels.count {
                selectCounterpart()
            }
        }
    }
    
    private func selectCounterpart() {
        if let selectedChannel = selectedChannel, ours.count > 0 && theirs.count > 0 {
            for ch in ours {
                if ch.shortChannelID == selectedChannel.shortChannelID {
                    chooseTheirsCounterpart()
                }
            }
            for ch in theirs {
                if ch.shortChannelID == selectedChannel.shortChannelID {
                    chooseOursCounterpart()
                }
            }
        } else {
            spinner.removeConnectingView()
            showAlert(vc: self, title: "Rebalancing issue...", message: "It does not look like you have enough suitable channels to rebalance with. This can usually happen if all your channels are 100% spendable or receivable.")
        }
    }
    
    private func chooseTheirsCounterpart()  {
        if theirs.count > 0 {
            let sortedArray = theirs.sorted { $0.receivableMsat < $1.receivableMsat }
            let sourceShortId = selectedChannel!.shortChannelID
            let destinationShortId = sortedArray[sortedArray.count - 1].shortChannelID
            rebalance(sourceShortId, destinationShortId)
        }
    }
    
    private func chooseOursCounterpart() {
        if ours.count > 0 {
            let sortedArray = ours.sorted { $0.spendableMsat < $1.spendableMsat }
            let sourceShortId = sortedArray[ours.count - 1].shortChannelID
            let destinationShortId = selectedChannel!.shortChannelID
            rebalance(sourceShortId, destinationShortId)
        }
    }
    
    private func rebalance(_ source: String, _ destination: String) {
        //outgoing_scid incoming_scid
        let p:[String:String] = ["outgoing_scid": source, "incoming_scid": destination]
        LightningRPC.sharedInstance.command(method: .rebalance, params: p) { [weak self] (response, errorDesc) in
            self?.refresh()
            if errorDesc != nil {
               showAlert(vc: self, title: "Error", message: errorDesc!)
            } else if let message = response as? String {
                showAlert(vc: self, title: "⚡️ Success ⚡️", message: message)
            } else {
                
                showAlert(vc: self, title: "", message: "\(String(describing: response))")
            }
        }
    }
    
    private func refresh() {
        activeChannels.removeAll()
        inactiveChannels.removeAll()
        pendingChannels.removeAll()
        ours.removeAll()
        theirs.removeAll()
        loadChannels()
        spinner.removeConnectingView()
    }

}
