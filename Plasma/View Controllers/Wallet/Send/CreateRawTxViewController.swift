//
//  CreateRawTxViewController.swift
//  BitSense
//
//  Created by Peter on 09/10/18.
//  Copyright © 2018 Denton LLC. All rights reserved.
//

import UIKit

class CreateRawTxViewController: UIViewController, UITextFieldDelegate {

    var fxRate = UserDefaults.standard.object(forKey: "fxRate") as? Double
    var txt = ""
    var invoice: DecodedInvoice?
    var invoiceString = ""
    var userSpecifiedAmount:Int?
    var withdrawing = false
    var paying = false
    var onchainAmountAvailable = ""
    var offchainSpendable = ""
    
    @IBOutlet weak private var invoiceAddressLabel: UILabel!
    @IBOutlet weak private var payOutlet: UIButton!
    @IBOutlet weak private var sweepButton: UIButton!
    @IBOutlet weak private var lightningWithdrawOutlet: UIButton!
    @IBOutlet weak private var fxRateLabel: UILabel!
    @IBOutlet weak private var addOutputOutlet: UIBarButtonItem!
    @IBOutlet weak private var playButtonOutlet: UIBarButtonItem!
    @IBOutlet weak private var amountInput: UITextField!
    @IBOutlet weak private var addressInput: UITextField!
    @IBOutlet weak private var actionOutlet: UIButton!
    @IBOutlet weak private var scanOutlet: UIButton!
    @IBOutlet weak private var receivingLabel: UILabel!
    @IBOutlet weak private var amountLabel: UILabel!
    
    var spinner = ConnectingView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        amountInput.delegate = self
        addressInput.delegate = self
        addTapGesture()
        
        if paying {
            lightningWithdrawOutlet.removeFromSuperview()
            invoiceAddressLabel.text = "Invoice or offer"
            sweepButton.alpha = 0.3
            sweepButton.isEnabled = false
            getTotalSpendable()
        }
        
        if withdrawing {
            payOutlet.removeFromSuperview()
            invoiceAddressLabel.text = "Address"
            fxRateLabel.text = onchainAmountAvailable
        }
        
        amountInput.placeholder = "amount in \(denomination())"
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
            decodeInvoice(invoiceInput)
        }
    }
    
    
    @IBAction func lightningWithdrawAction(_ sender: Any) {
        guard let item = addressInput.text, item != "" else {
            showAlert(vc: self, title: "", message: "Add a recipient address first.")
            return
        }
        
        if item.hasPrefix("lntb") || item.hasPrefix("lightning:") || item.hasPrefix("lnbc") || item.hasPrefix("lnbcrt") || item.hasPrefix("lno") {
            decodeInvoice(item.replacingOccurrences(of: "lightning:", with: ""))
        } else {
            promptWithdrawalLightning(item)
        }
    }
    
    
    private func getTotalSpendable() {
        spinner.addConnectingView(vc: self, description: "")
        LightningRPC.sharedInstance.command(method: .listpeerchannels, params: [:]) { [weak self] (listPeerChannels, errorDesc) in
            guard let self = self else { return }
            
            guard let listPeerChannels = listPeerChannels as? ListPeerChannels else {
                spinner.removeConnectingView()
                showAlert(vc: self, title: "", message: errorDesc ?? "Unknown error fetching channels.")
                return
            }
            
            let channels = listPeerChannels.channels
            
            guard channels.count > 0 else {
                spinner.removeConnectingView()
                showAlert(vc: self, title: "", message: "No channels yet.")
                return
            }
            
            var totalSpendable = 0
            
            for (i, channel) in channels.enumerated() {
                totalSpendable += channel.spendableMsat ?? 0
                
                if i + 1 == channels.count {
                    var spendableString = ""
                    
                    switch denomination() {
                    case "BTC":
                        offchainSpendable = totalSpendable.msatToBtc
                        spendableString =  Double(totalSpendable.msatToBtc)!.btcBalanceWithSpaces
                        
                    case "SATS":
                        offchainSpendable = totalSpendable.msatToSat
                        spendableString = totalSpendable.msatToSat
                        
                    default:
                        offchainSpendable = totalSpendable.msatToFiat!
                        spendableString = totalSpendable.msatToFiat!
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        fxRateLabel.text = spendableString
                    }
                }
            }
            
            spinner.removeConnectingView()
        }
    }
    
        
    private func promptWithdrawalLightning(_ recipient: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var title = "Withdraw from lightning wallet?"
            var mess = "This action will withdraw the amount specified to the given address from your lightning wallet"
            
            if self.amountInput.text == "" || self.amountInput.text == "0" || self.amountInput.text == "0.0" {
                title = "Withdraw ALL onchain funds?\n"
                mess = "This action will withdraw the TOTAL available onchain amount to:\n\n\(recipient)"
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
        let fiatCurrency = UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
        
        if amount > 0.0 {
            switch denomination() {
            case "BTC":
                sats = Int(amount * 100000000.0)
                title = "Withdraw \(amount.avoidNotation) btc (\(sats) sats) from lightning wallet to \(address)?"
            case "SATS":
                sats = Int(dblAmount)
                title = "Withdraw \(dblAmount) sats from lightning wallet to \(address)?"
            default:
                guard let fxRate = fxRate else { return }
                let btcamount = rounded(number: amount / fxRate)
                sats = Int(btcamount * 100000000.0)
                title = "Withdraw $\(dblAmount) \(fiatCurrency) (\(sats) sats) from lightning wallet to \(address)?"
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
                
                spinner.addConnectingView(vc: self, description: "decoding...")
                LightningRPC.sharedInstance.command(method: .decode, params: ["invoice": address]) { [weak self] (decoded, errorDesc) in
                    guard let self = self else { return }
                    
                    spinner.removeConnectingView()
                    
                    guard let decoded = decoded as? DecodedInvoice else { return }
                    
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
                            }
                        } else {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                
                                amountInput.isUserInteractionEnabled = true
                                lightningWithdrawOutlet.isEnabled = true
                                sweepButton.alpha = 1.0
                                sweepButton.isEnabled = true
                            }
                        }
                    } else {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            
                            sweepButton.alpha = 1.0
                            sweepButton.isEnabled = true
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
    
    
    @IBAction func scanAction(_ sender: Any) {
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
        if withdrawing {
            guard let recipient = addressInput.text, recipient != "" else {
                showAlert(vc: self, title: "", message: "Input a recipient address first.")
                return
            }
            
            amountInput.text = "0"
            promptWithdrawalLightning(recipient)
        }
        
        if paying {
            showAlert(vc: self, title: "", message: "Plasma will attempt to send all available funds.")
            amountInput.text = offchainSpendable
            guard let invoice = addressInput.text, invoice != "" else { return }
            decodeInvoice(invoice)
        }
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
            
            decodeInvoice(fetchInvoice.invoice)
        }
    }
    
    
    private func decodeInvoice(_ invoice: String) {
        spinner.addConnectingView(vc: self, description: "decoding lightning invoice...")
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
                    enterAnAmount(invoice)
                }
                
            default:
                processInvoiceToPay(decoded: decoded, invoice: invoice)
            }
        }
    }
    
    
    private func enterAnAmount(_ invoice: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
                    self.addressInput.text = invoice
                    self.amountInput.alpha = 1
                    self.amountLabel.alpha = 1
                    self.sweepButton.alpha = 1
                    self.sweepButton.isEnabled = true
                    self.amountInput.isEnabled = true
                    
                    showAlert(vc: self, title: "No amount specified by invoice.", message: "Enter an amount to pay to proceed.")
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
        switch denomination() {
        case "BTC":
            let dblAmount = amountText.doubleValue
            
            guard dblAmount > 0.0 else {
                self.spinner.removeConnectingView()
                showAlert(vc: self, title: "No amount specified.", message: "You need to enter an amount to send for an invoice that does not include one.")
                return nil
            }
            return Int(dblAmount * 100000000000.0)
            
        case "SATS":
            guard let dblAmount = Double(amountText.digits) else { return nil }
            
            guard dblAmount > 0.0 else {
                self.spinner.removeConnectingView()
                showAlert(vc: self, title: "No amount specified.", message: "You need to enter an amount to send for an invoice that does not include one.")
                return nil
            }
            return Int(dblAmount * 1000.0)
            
        default:
            if let doubeAmount = Double(amountText) {
                guard let fxRate = self.fxRate else { return nil }
                let btcamount = rounded(number: doubeAmount / fxRate)
                return Int(btcamount * 100000000000.0)
                
            } else {
                // Handles and currency symbols.
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                
                guard let number = formatter.number(from: amountText) else {
                    showAlert(vc: self, title: "", message: "Error converting fiat string to number.")
                    return nil
                }
                
                guard let fxRate = self.fxRate else { return nil }
                let btcamount = rounded(number: number.doubleValue / fxRate)
                return Int(btcamount * 100000000000.0)
            }
            
        }
    }
    
    
    
    private func promptToSendLightningPayment(invoice: String, decoded: DecodedInvoice, msat: Int?) {
        self.invoice = decoded
        if let msat = msat {
            userSpecifiedAmount = msat
        }
        invoiceString = invoice
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return}
            
            performSegue(withIdentifier: "segueToLightningConf", sender: self)
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
                    UserDefaults.standard.set("BTC", forKey: "denomination")
                }
                
                showAlert(vc: self, title: "BIP21 Invoice\nThis automatically sets the denomination to BTC.", message: "Address: \(address)\n\nAmount: \(amountText) btc\n\nLabel: " + (label ?? "no label") + "\n\nMessage: \((message ?? "no message"))")
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
                vc.onDoneBlock = { addrss in
                    guard let addrss = addrss else { return }
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        let potentialLightning = addrss.lowercased().replacingOccurrences(of: "lightning:", with: "")
                        
                        if potentialLightning.hasPrefix("lntb") || potentialLightning.hasPrefix("lightning:") || potentialLightning.hasPrefix("lnbc") || potentialLightning.hasPrefix("lnbcrt") || potentialLightning.hasPrefix("lno") {
                            
                            decodeInvoice(potentialLightning)
                        }
                    }
                }
            }
            
            
        case "segueToLightningConf":
            guard let vc = segue.destination as? ConfirmLightningPaymentViewController else { fallthrough }
            
            vc.fxRate = self.fxRate
            vc.invoice = self.invoice
            vc.invoiceString = self.invoiceString
            vc.userSpecifiedAmount = self.userSpecifiedAmount
            spinner.removeConnectingView()
            
        default:
            break
        }
    }
}

