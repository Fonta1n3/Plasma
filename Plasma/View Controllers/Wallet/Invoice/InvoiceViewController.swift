//
//  InvoiceViewController.swift
//  BitSense
//
//  Created by Peter on 21/03/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import UIKit

class InvoiceViewController: UIViewController, UITextFieldDelegate {
    
    var invoiceString = String()
    let spinner = ConnectingView()
    var bolt11 = false
    var bolt12 = false
    
    @IBOutlet weak var incomingCapacity: UILabel!
    @IBOutlet weak var expirySwitch: UISwitch!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet var amountField: UITextField!
    @IBOutlet private weak var messageField: UITextField!
    @IBOutlet private weak var bolt12Outlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .compact
        }
        expirySwitch.isOn = false
        datePicker.isEnabled = false
        datePicker.alpha = 0.1
        confirgureFields()
        configureTap()
        addDoneButtonOnKeyboard()
        bolt12Outlet.isEnabled = false
        listConfigs()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        bolt11 = false
        bolt12 = false
    }
    
    
    @IBAction func dateSwitchAction(_ sender: Any) {
        datePicker.isEnabled = expirySwitch.isOn
        
        if expirySwitch.isOn {
            datePicker.alpha = 1
        } else {
            datePicker.alpha = 0.1
        }
    }
    
    
    @IBAction func generateBolt11(_ sender: Any) {
        spinner.addConnectingView(vc: self, description: "")
        bolt11 = true
        createBolt11Invoice()
    }
    
    
    @IBAction func generateBolt12Offer(_ sender: Any) {
        spinner.addConnectingView(vc: self, description: "")
        bolt12 = true
        createBolt12Invoice()
    }
    
    
    private func denomination() -> String {
        return UserDefaults.standard.object(forKey: "denomination") as? String ?? "BTC"
        
    }
    
    
    private func setDelegates() {
        messageField.delegate = self
        amountField.delegate = self
    }
    
    
    private func confirgureFields() {
        amountField.placeholder =  "Optional amount in \(denomination())."
        messageField.placeholder = "Optional description."
    }
    
    
    private func configureTap() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        amountField.removeGestureRecognizer(tap)
        messageField.removeGestureRecognizer(tap)
    }
    
    
    private func configureView(_ view: UIView) {
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 0.5
    }
    
    
    private func listConfigs() {
        spinner.addConnectingView(vc: self, description: "fetching config...")
        LightningRPC.sharedInstance.command(method: .listconfigs, params: [:]) { [weak self] (listConfigs, errorDesc) in
            guard let self = self else { return }
                                
            guard let listConfigs = listConfigs as? ListConfigs else {
                spinner.removeConnectingView()
                showAlert(vc: self, title: "Error fetching config.", message: errorDesc ?? "unknown")
                return
            }
            
            if listConfigs.configs.experimentalOffers.set {
                enableBolt12Button()
            }
            
            getIncomingCapacity()
        }
    }
    
    
    private func getIncomingCapacity() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            spinner.label.text = "fetching incoming capacity..."
        }
        
        LightningRPC.sharedInstance.command(method: .listpeerchannels, params: [:]) { [weak self] (listPeerChannels, errorDesc) in
            guard let self = self else { return }
            
            spinner.removeConnectingView()
            
            guard let listPeerChannels = listPeerChannels as? ListPeerChannels else {
                showAlert(vc: self, title: "", message: errorDesc ?? "Unknown error fetching channels.")
                return
            }
            
            guard listPeerChannels.channels.count > 0 else {
                showAlert(vc: self, title: "", message: "No channels yet.")
                return
            }
            
            var totalReceivable = 0
            
            for (i, channel) in listPeerChannels.channels.enumerated() {
                totalReceivable += channel.receivableMsat ?? 0
                
                if i + 1 == listPeerChannels.channels.count {
                    var incomingString = ""
                    
                    switch denomination() {
                    case "BTC":
                        incomingString = Double(totalReceivable.msatToBtc)!.btcBalanceWithSpaces
                        
                    case "SATS":
                        incomingString = totalReceivable.msatToSat
                        
                    default:
                        incomingString = totalReceivable.msatToFiat!
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        incomingCapacity.text = incomingString
                    }
                }
            }
        }
    }
    
    
    private func enableBolt12Button() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            bolt12Outlet.isEnabled = true
        }
    }
    
            
    private func createBolt11Invoice() {
        var param:[String:String] = [:]
        let label = "Plasma invoice \(randomString(length: 6))"
        var description = "Plasma invoice"
        
        if let descriptionText = messageField.text, description != "" {
            description = descriptionText
        }
        
        param["description"] = description
        param["label"] = label
        
        if let amountString = amountField.text, amountString != "", let amount = Double(amountString) {
            switch denomination() {
            case "BTC":
                param["amount_msat"] = "\(amount.avoidNotation)btc"
                
            case "SATS":
                param["amount_msat"] = "\(Int(amount))sat"
                
            default:
                if let fxRate = UserDefaults.standard.object(forKey: "fxRate") as? Double {
                    let btcAmount = (Double(amount) / fxRate).avoidNotation
                    param["amount_msat"] = "\(btcAmount)btc"
                }
            }
        } else {
            param["amount_msat"] = "any"
        }
        
        if expirySwitch.isOn {
            let myTimeStamp = datePicker.date.timeIntervalSinceNow
            param["expiry"] = "\(Int(myTimeStamp))"
        }
        
        LightningRPC.sharedInstance.command(method: .invoice, params: param) { [weak self] (invoice, errorDesc) in
            guard let self = self else { return }
            
            guard let invoice = invoice as? Invoice else {
                self.spinner.removeConnectingView()
                showAlert(vc: self, title: "Error", message: errorDesc ?? "we had an issue getting your lightning invoice")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.showLightningInvoice(invoice.bolt11)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let warning = invoice.warningMpp {
                    showAlert(vc: self, title: "", message: warning)
                }
                
                if let warning = invoice.warningOffline {
                    showAlert(vc: self, title: "", message: warning)
                }
                
                if let warning = invoice.warningCapacity {
                    showAlert(vc: self, title: "", message: warning)
                }
                
                if let warning = invoice.warningDeadends {
                    showAlert(vc: self, title: "", message: warning)
                }
                
                if let warning = invoice.warningPrivateUnused {
                    showAlert(vc: self, title: "", message: warning)
                }
            }
        }
    }
    
    
    private func createBolt12Invoice() {
        // amount description [issuer] [label] [quantity_max] [absolute_expiry] [recurrence] [recurrence_base] [recurrence_paywindow] [recurrence_limit] [single_use]
        var param:[String:String] = [:]

        if let amountString = amountField.text, amountString != "", let amount = Double(amountString) {
            switch denomination() {
            case "BTC":
                param["amount"] = "\(amount.avoidNotation)btc"
                
            case "SATS":
                param["amount"] = "\(Int(amount))sats"
                
            default:
                if let fxRate = UserDefaults.standard.object(forKey: "fxRate") as? Double {
                    let btcAmount = (Double(amount) / fxRate).avoidNotation
                    param["amount"] = "\(btcAmount)btc"
                }
            }
        } else {
            param["amount"] = "any"
        }
        
        if expirySwitch.isOn {
            let myTimeStamp = datePicker.date.timeIntervalSince1970
            param["absolute_expiry"] = "\(Int(myTimeStamp))"
        }

        param["description"] = messageField.text

        LightningRPC.sharedInstance.command(method: .offer, params: param) { [weak self] (offer, errorDesc) in
            guard let self = self else { return }

            guard let offer = offer as? Offer else {
                self.spinner.removeConnectingView()
                showAlert(vc: self, title: "Error", message: errorDesc ?? "we had an issue getting your lightning offer")
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.showLightningInvoice(offer.bolt12)
            }
        }
    }
    
    
    private func showLightningInvoice(_ invoice: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            invoiceString = invoice
            spinner.removeConnectingView()
            performSegue(withIdentifier: "segueToShowInvoiceQr", sender: self)
        }
    }
    

    @objc func doneButtonAction() {
        amountField.resignFirstResponder()
        messageField.resignFirstResponder()
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar = UIToolbar()
        doneToolbar.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
        
        let items = NSMutableArray()
        items.add(flexSpace)
        items.add(done)
        
        doneToolbar.items = (items as! [UIBarButtonItem])
        doneToolbar.sizeToFit()
        
        self.amountField.inputAccessoryView = doneToolbar
        self.messageField.inputAccessoryView = doneToolbar
    }
    
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToShowInvoiceQr" {
            guard let vc = segue.destination as? QRDisplayerViewController else { return }
            
            vc.text = invoiceString
            
            if bolt11 {
                vc.headerText = "Bolt11 Invoice"
            }
            if bolt12 {
                vc.headerText = "Bolt12 Offer"
            }
        }
    }
}
