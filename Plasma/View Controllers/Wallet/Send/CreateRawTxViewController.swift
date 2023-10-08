//
//  CreateRawTxViewController.swift
//  BitSense
//
//  Created by Peter on 09/10/18.
//  Copyright © 2018 Denton LLC. All rights reserved.
//

import UIKit

class CreateRawTxViewController: UIViewController, UITextFieldDelegate {

    var index = 0
    var isFiat = false
    var isBtc = true
    var isSats = false
    var fxRate:Double?
    var address = String()
    var amount = String()
    var txt = ""
    let ud = UserDefaults.standard
    var invoice: DecodedInvoice?
    var invoiceString = ""
    let fiatCurrency = UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
    var userSpecifiedAmount:Int?
    var withdrawing = false
    var paying = false
    var onchainAmountAvailable = ""
    
    @IBOutlet weak private var invoiceAddressLabel: UILabel!
    @IBOutlet weak private var payOutlet: UIButton!
    @IBOutlet weak private var sweepButton: UIButton!
    @IBOutlet weak private var lightningWithdrawOutlet: UIButton!
    @IBOutlet weak private var fxRateLabel: UILabel!
    @IBOutlet weak private var addOutputOutlet: UIBarButtonItem!
    @IBOutlet weak private var playButtonOutlet: UIBarButtonItem!
    @IBOutlet weak private var amountInput: UITextField!
    @IBOutlet weak private var addressInput: UITextField!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var actionOutlet: UIButton!
    @IBOutlet weak private var scanOutlet: UIButton!
    @IBOutlet weak private var receivingLabel: UILabel!
    
    var spinner = ConnectingView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        amountInput.delegate = self
        addressInput.delegate = self
        addTapGesture()
        if address != "" {
            addAddress(address)
        }
        
        if paying {
            lightningWithdrawOutlet.removeFromSuperview()
            invoiceAddressLabel.text = "Invoice or offer"
        }
        
        if withdrawing {
            payOutlet.removeFromSuperview()
            invoiceAddressLabel.text = "Address"
            fxRateLabel.text = onchainAmountAvailable
        }
        
        amountInput.placeholder = "amount in \(denomination())"
        
        if paying {
            getTotalSpendable()
        }
    }
        
    
    @IBAction func pasteAction(_ sender: Any) {
        guard let item = UIPasteboard.general.string else { return }
        processBIP21(url: item)
    }
    
    
    @IBAction func createOnchainAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.amountInput.resignFirstResponder()
            self.addressInput.resignFirstResponder()
        }
        
        guard let invoiceInput = addressInput.text else {
            showAlert(vc: self, title: "", message: "Enter an address or invoice.")
            return
        }
                
        if let invoice = self.invoice {
            processInvoiceToPay(decoded: invoice, invoice: invoiceInput)
        } else {
            decodeFromCL(invoiceInput)
        }
    }
    
    
    @IBAction func lightningWithdrawAction(_ sender: Any) {
        guard let item = addressInput.text, item != "" else {
            showAlert(vc: self, title: "", message: "Add a recipient address first.")
            return
        }
        
        if item.hasPrefix("lntb") || item.hasPrefix("lightning:") || item.hasPrefix("lnbc") || item.hasPrefix("lnbcrt") || item.hasPrefix("lno") {
            decodeLighnting(invoice: item.replacingOccurrences(of: "lightning:", with: ""))
        } else {
            promptWithdrawalLightning(item)
        }
    }
    
    
    private func getTotalSpendable() {
        LightningRPC.sharedInstance.command(method: .listpeerchannels, params: [:]) { [weak self] (listPeerChannels, errorDesc) in
            guard let self = self else { return }
            
            guard let listPeerChannels = listPeerChannels as? ListPeerChannels else {
                self.spinner.removeConnectingView()
                showAlert(vc: self, title: "", message: errorDesc ?? "Unknown error fetching channels.")
                return
            }
            
            let channels = listPeerChannels.channels
            
            guard channels.count > 0 else {
                self.spinner.removeConnectingView()
                showAlert(vc: self, title: "", message: "No channels yet.")
                return
            }
            
            var totalSpendable = 0
            
            for (i, channel) in channels.enumerated() {
                totalSpendable += channel.spendableMsat
                
                if i + 1 == channels.count {
                    var spendableString = ""
                    
                    switch denomination() {
                    case "BTC":
                        spendableString = Double(totalSpendable.msatToBtc)!.btcBalanceWithSpaces
                        
                    case "SATS":
                        spendableString = totalSpendable.msatToSat
                        
                    default:
                        spendableString = totalSpendable.msatToFiat!
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        fxRateLabel.text = spendableString
                    }
                }
            }
        }
    }
    
        
    private func promptWithdrawalLightning(_ recipient: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var title = "Withdraw from lightning wallet?"
            var mess = "This action will withdraw the amount specified to the given address from your lightning wallet"
            
            if self.amountInput.text == "" || self.amountInput.text == "0" || self.amountInput.text == "0.0" {
                title = "Withdraw ALL onchain funds from your ⚡️ wallet?\n"
                mess = "This action will withdraw the TOTAL available onchain amount from your lightning internal onchain wallet to:\n\n\(recipient)"
            }
            
            let alert = UIAlertController(title: title, message: mess, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Withdraw now", style: .default, handler: { action in
                self.withdrawLightningSanity()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    private func withdrawLightningSanity() {
        guard let amountString = amountInput.text, let address = addressInput.text, address != "" else {
            showAlert(vc: self, title: "", message: "Add an address first.")// add option to withdraw to onchain wallet too
            return
        }
                
        confirmLightningWithdraw(address, amountString.doubleValue)
    }
    
    
    private func confirmLightningWithdraw(_ address: String, _ amount: Double) {
        var title = ""
        var sats = Int()
        
        let amountString = amountInput.text ?? ""
        let dblAmount = amountString.doubleValue
        
        if amount > 0.0 {
            if isFiat {
                guard let fxRate = fxRate else { return }
                let btcamount = rounded(number: amount / fxRate)
                sats = Int(btcamount * 100000000.0)
                title = "Withdraw $\(dblAmount) \(fiatCurrency) (\(sats) sats) from lightning wallet to \(address)?"
                
            } else if isSats {
                sats = Int(dblAmount)
                title = "Withdraw \(dblAmount) sats from lightning wallet to \(address)?"
                
            } else {
                sats = Int(amount * 100000000.0)
                title = "Withdraw \(amount.avoidNotation) btc (\(sats) sats) from lightning wallet to \(address)?"
            }
        } else {
            sats = 0
            title = "Sweep ALL funds from onchain lightning wallet?"
        }
                
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: title, message: "This action is not reversable!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Withdraw now", style: .default, handler: { action in
                self.withdrawLightningNow(address: address, sats: sats)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func withdrawLightningNow(address: String, sats: Int) {
        spinner.addConnectingView(vc: self, description: "withdrawing from lightning wallet...")
        withdrawFromCL(address: address, sats: sats)
    }
        
    private func withdrawFromCL(address: String, sats: Int) {
        var param:[String:String] = ["destination":address, "satoshi":"\(sats)"]
        if sats == 0 {
            param["satoshi"] = "all"
        }
        //destination satoshi [feerate] [minconf] [utxos]
        LightningRPC.sharedInstance.command(method: .withdraw, params: param) { [weak self] (withdraw, errorDesc) in
            guard let self = self else { return }
            
            self.spinner.removeConnectingView()
            
            guard let _ = withdraw as? Withdraw else {
                showAlert(vc: self, title: "", message: errorDesc ?? "unknow error")
                return
            }
            
            showAlert(vc: self, title: "", message: "Withdraw complete ✓")
        }
    }
    

    private func addAddress(_ address: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.addressInput.text = address
            
            switch address.lowercased() {
                case _ where address.hasPrefix("lntb"),
                _ where address.hasPrefix("lno"),
                _ where address.hasPrefix("lni"),
                _ where address.hasPrefix("lnbc"),
                _ where address.hasPrefix("lnbcrt"):
                
                LightningRPC.sharedInstance.command(method: .decode, params: ["invoice": address]) { [weak self] (decoded, errorDesc) in
                    guard let self = self else { return }
                    
                    guard let decoded = decoded as? DecodedInvoice else {
                        self.spinner.removeConnectingView()
                        return
                    }
                    
                    self.invoice = decoded
                    
                    var amountMsat: Int?
                    
                    if decoded.offerAmountMsat != nil {
                        amountMsat = decoded.offerAmountMsat
                    }
                    if decoded.invoiceAmountMsat != nil {
                        amountMsat = decoded.invoiceAmountMsat
                    }
                    if decoded.amountMsat != nil {
                        amountMsat = decoded.amountMsat
                    }
                    
                    if let amountMsat = amountMsat {
                        var amountText = ""
                        
                        switch denomination() {
                        case "BTC":
                            amountText = (Double(amountMsat) / 100000000000.0).avoidNotation
                            
                        case "SATS":
                            amountText = "\(Int(Double(amountMsat) / 1000.0))"
                            
                        default:
                            if let fiatAmount = amountMsat.msatToFiat {
                                amountText = fiatAmount
                            }
                        }
                        
                        if amountText != "" {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                
                                amountInput.text = amountText
                                amountInput.isUserInteractionEnabled = false
                                lightningWithdrawOutlet.isEnabled = false
                                sweepButton.isEnabled = false
                            }
                        } else {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                
                                amountInput.isUserInteractionEnabled = true
                                lightningWithdrawOutlet.isEnabled = true
                                sweepButton.isEnabled = true
                            }
                        }
                    }
                }
            default:
                break
            }
        }
    }
    
    
    private func denomination() -> String {
        return UserDefaults.standard.object(forKey: "denomination") as? String ?? "BTC"
    }
    
    
    @IBAction func scanNow(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToScannerToGetAddress", sender: vc)
        }
    }
    
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: User Actions
    
    @IBAction func sweep(_ sender: Any) {
        
    }
    
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        amountInput.resignFirstResponder()
        addressInput.resignFirstResponder()
    }
    
        
    //MARK: Textfield methods
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == amountInput, let text = textField.text, string != "" else { return true }
        
        guard text.contains(".") else { return true }
        
        let arr = text.components(separatedBy: ".")
        
        guard arr.count > 0 else { return true }
        
        return arr[1].count < 8
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        
        if textField == addressInput && addressInput.text != "" {
            processBIP21(url: addressInput.text!)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    //MARK: Helpers
    
    private func decodeLighnting(invoice: String) {
        spinner.addConnectingView(vc: self, description: "decoding lightning invoice...")
        decodeFromCL(invoice)
    }
        
    
    private func fetchInvoice(offer: String, amountMsat: Int) {
        // fetchinvoice offer [amount_msat] [quantity] [recurrence_counter] [recurrence_start] [recurrence_label] [timeout] [payer_note]
        var param:[String:String] = ["offer": offer]
        param["amount_msat"] = "\(amountMsat)"
        
        LightningRPC.sharedInstance.command(method: .fetchinvoice, params: param) { [weak self] (fetchInvoice, errorDesc) in
            guard let self = self else { return }

            guard let fetchInvoice = fetchInvoice as? FetchInvoice else {
                self.spinner.removeConnectingView()
                showAlert(vc: self, title: "There was an issue fetching the invoice.", message: errorDesc ?? "Unknown error.")
                return
            }
            
            decodeFromCL(fetchInvoice.invoice)
        }
    }
    
    private func decodeFromCL(_ invoice: String) {
        LightningRPC.sharedInstance.command(method: .decode, params: ["invoice": invoice]) { [weak self] (decoded, errorDesc) in
            guard let self = self else { return }
            
            guard let decoded = decoded as? DecodedInvoice else {
                self.spinner.removeConnectingView()
                return
            }
            
            switch decoded.type {
            case "bolt12 offer":
                if let msatAmount = decoded.offerAmountMsat {
                    fetchInvoice(offer: invoice, amountMsat: msatAmount)
                    
                } else {
                    guard let amount = amountInput.text else {
                        self.spinner.removeConnectingView()
                        showAlert(vc: self, title: "", message: "That offer does not specify an amount, please enter one first.")
                        return
                    }
                    
                    guard let msatAmount = msatAmount(amountText: amount) else {
                        self.spinner.removeConnectingView()
                        showAlert(vc: self, title: "", message: "Unable to convert Core Lightning msat string to int.")
                        return
                    }
                    
                    fetchInvoice(offer: invoice, amountMsat: msatAmount)
                }
            default:
                processInvoiceToPay(decoded: decoded, invoice: invoice)
            }
        }
    }
    
    
    private func processInvoiceToPay(decoded: DecodedInvoice, invoice: String) {
        if decoded.amountMsat != nil {
            promptToSendLightningPayment(invoice: invoice, decoded: decoded, msat: nil)
            
        } else if decoded.invoiceAmountMsat != nil {
            promptToSendLightningPayment(invoice: invoice, decoded: decoded, msat: nil)
                        
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                guard let amountText = self.amountInput.text, amountText != "" else {
                    self.spinner.removeConnectingView()
                    showAlert(vc: self, title: "No amount specified.", message: "You need to enter an amount to send for an invoice that does not include one.")
                    return
                }
                
                guard let msats = self.msatAmount(amountText: amountText) else {
                    self.spinner.removeConnectingView()
                    showAlert(vc: self, title: "", message: "There was an issue converting the amount to msats.")
                    return
                }

                promptToSendLightningPayment(invoice: invoice, decoded: decoded, msat: msats)
            }
        }
    }
    
    private func msatAmount(amountText: String) -> Int? {
        let dblAmount = amountText.doubleValue
        
        guard dblAmount > 0.0 else {
            self.spinner.removeConnectingView()
            showAlert(vc: self, title: "No amount specified.", message: "You need to enter an amount to send for an invoice that does not include one.")
            return nil
        }
        
        if self.isFiat {
            guard let fxRate = self.fxRate else { return nil }
            let btcamount = rounded(number: dblAmount / fxRate)
            return Int(btcamount * 100000000000.0)
            
        } else if self.isSats {
            return Int(dblAmount * 1000.0)
            
        } else {
            return Int(dblAmount * 100000000000.0)
        }
    }
    
    private func promptToSendLightningPayment(invoice: String, decoded: DecodedInvoice, msat: Int?) {
        FiatConverter.sharedInstance.getFxRate { [weak self] fxRate in
            guard let self = self else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.fxRate = fxRate
                self.invoice = decoded
                if let msat = msat {
                    self.userSpecifiedAmount = msat
                }
                self.invoiceString = invoice
                self.performSegue(withIdentifier: "segueToLightningConf", sender: self)
            }
        }
    }
    
    
    private func pay(invoiceString: String, msat: Int?, invoice: DecodedInvoice) {
        //bolt11 [amount_msat] [label] [riskfactor] [maxfeepercent] [retry_for] [maxdelay] [exemptfee] [localinvreqid] [exclude] [maxfee] [description]
        var param:[String:String] = [:]
        param["bolt11"] = invoiceString
        
        if let msat = msat {
            param["amount_msat"] = "\(msat)"
        }
        
        if let desc = invoice.description {
            param["description"] = desc
        } else if let desc = invoice.offerDescription {
            param["description"] = desc
        }
        
        LightningRPC.sharedInstance.command(method: .pay, params: param) { [weak self] (paid, errorDesc) in
            guard let self = self else { return }
            
            self.spinner.removeConnectingView()
            
            guard let paid = paid as? Pay else {
                showAlert(vc: self, title: "Error", message: errorDesc ?? "unknown error")
                return
            }
            
            guard paid.status == "complete" else {
                showAlert(vc: self, title: "Payment failed.", message: errorDesc ?? "Unknown error.")
                return
            }
            
            let feeMsat = paid.amountSentMsat - paid.amountMsat
            
            var amountReceived = ""
            
            switch denomination() {
            case "BTC":
                amountReceived = paid.amountMsat.msatToBtc
            case "SATS":
                amountReceived = paid.amountMsat.msatToSats
            default:
                amountReceived = paid.amountMsat.msatToFiat!
            }
            
            showAlert(vc: self, title: "Paid ✓", message: "Paid \(amountReceived) for a fee of \(feeMsat) msats.")
        }
    }
        
    
    func processBIP21(url: String) {
        let (address, amount, label, message) = AddressParser.parse(url: url)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.addressInput.resignFirstResponder()
            self.amountInput.resignFirstResponder()
            
            guard let address = address else {
                showAlert(vc: self, title: "", message: "Not a supported invoice, offer or address format.")
                return
            }
            
            self.addAddress(address)
            
            if amount != nil || label != nil || message != nil {
                var amountText = "not specified"
                
                if amount != nil {
                    amountText = amount!.avoidNotation
                    self.amountInput.text = amountText
                    self.isFiat = false
                    self.isBtc = true
                    self.isSats = false
                    self.ud.set("btc", forKey: "unit")
                    //self.btcEnabled()
                }
                
                showAlert(vc: self, title: "BIP21 Invoice\n", message: "Address: \(address)\n\nAmount: \(amountText) btc\n\nLabel: " + (label ?? "no label") + "\n\nMessage: \((message ?? "no message"))")
            }
        }
    }
    
    
        
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == addressInput {
            if textField.text != "" {
                textField.becomeFirstResponder()
            } else {
                if let string = UIPasteboard.general.string {
                    textField.becomeFirstResponder()
                    textField.text = string
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        textField.resignFirstResponder()
                    }
                } else {
                    textField.becomeFirstResponder()
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "segueToScannerToGetAddress":
            if #available(macCatalyst 14.0, *) {
                guard let vc = segue.destination as? QRScannerViewController else { fallthrough }
                
                vc.isScanningAddress = true
                
                print("scanning")
                
                vc.onDoneBlock = { addrss in
                    guard let addrss = addrss else { return }
                    
                    print("addrss: \(addrss)")
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        let potentialLightning = addrss.lowercased().replacingOccurrences(of: "lightning:", with: "")
                        
                        if potentialLightning.hasPrefix("lntb") || potentialLightning.hasPrefix("lightning:") || potentialLightning.hasPrefix("lnbc") || potentialLightning.hasPrefix("lnbcrt") || potentialLightning.hasPrefix("lno") {
                            
                            decodeLighnting(invoice: potentialLightning)
                        }
                    }
                }
            }
            
            
        case "segueToLightningConf":
            guard let vc = segue.destination as? ConfirmLightningPaymentViewController else { fallthrough }
            
            vc.fxRate = self.fxRate
            vc.invoice = self.invoice
            vc.userSpecifiedAmount = self.userSpecifiedAmount
            self.spinner.removeConnectingView()
            
            vc.doneBlock = { [weak self] confirmed in
                guard let self = self else { return }
                
                if confirmed {
                    self.spinner.addConnectingView(vc: self, description: "paying lightning invoice...")
                    
                    if let userSpecifiedAmount = self.userSpecifiedAmount {
                        self.pay(invoiceString: self.invoiceString, msat: userSpecifiedAmount, invoice: self.invoice!)
                    } else {
                        self.pay(invoiceString: self.invoiceString, msat: nil, invoice: self.invoice!)
                    }
                    
                } else {
                    self.invoice = nil
                    self.invoiceString = ""
                }
            }
            
        default:
            break
        }
    }
}
