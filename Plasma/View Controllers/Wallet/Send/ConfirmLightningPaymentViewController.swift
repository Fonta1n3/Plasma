//
//  ConfirmLightningPaymentViewController.swift
//  FullyNoded
//
//  Created by Peter Denton on 7/11/21.
//  Copyright © 2021 Fontaine. All rights reserved.
//

import UIKit

class ConfirmLightningPaymentViewController: UIViewController, UINavigationControllerDelegate {
    
    var fxRate:Double?
    var invoice: DecodedInvoice!
    var invoiceString: String!
    var spinner = ConnectingView()
    var userSpecifiedAmount: Int?
    
    @IBOutlet weak var expiryHeader: UILabel!
    @IBOutlet weak var descHeader: UILabel!
    @IBOutlet weak var recipientHeader: UILabel!
    @IBOutlet weak var amountHeader: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var expiryLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var checkMarkImage: UIImageView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var paymentSentLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        spinner.addConnectingView(vc: self, description: "")
        doneButton.alpha = 0
        paymentSentLabel.alpha = 0
        checkMarkImage.alpha = 0
        amountLabel.alpha = 0
        recipientLabel.alpha = 0
        expiryLabel.alpha = 0
        sendButton.alpha = 0
        sendButton.layer.cornerRadius = 8
        sendButton.clipsToBounds = true
        load()
    }
    
    
    @IBAction func doneAction(_ sender: Any) {
        close()
    }
    
    
    @IBAction func cancelAction(_ sender: Any) {
        close()
    }
    
    
    @IBAction func closeAction(_ sender: Any) {
        close()
    }
    
    
    @IBAction func sendAction(_ sender: Any) {
        spinner.addConnectingView(vc: self, description: "paying lightning invoice...")
        
        if let userSpecifiedAmount = userSpecifiedAmount {
            pay(invoiceString: invoiceString, msat: userSpecifiedAmount, invoice: self.invoice!)
        } else {
            pay(invoiceString: invoiceString, msat: nil, invoice: invoice!)
        }
    }
    
    
    private func pay(invoiceString: String, msat: Int?, invoice: DecodedInvoice) {
        //bolt11 [amount_msat] [label] [riskfactor] [maxfeepercent] [retry_for] [maxdelay] [exemptfee] [localinvreqid] [exclude] [maxfee] [description]
        var param:[String:String] = [:]
        param["bolt11"] = invoiceString
        if let msat = msat {
            param["amount_msat"] = "\(msat)"
        }
        
        param["description"] = invoice.description ?? invoice.offerDescription ?? ""
        
        LightningRPC.sharedInstance.command(method: .pay, params: param) { [weak self] (paid, errorDesc) in
            guard let self = self else { return }
            
            guard let paid = paid as? Pay, paid.status == "complete" else {
                self.spinner.removeConnectingView()
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
            
            sent(amount: amountReceived, fee: "\(feeMsat)")
        }
    }
    
    
    private func sent(amount: String, fee: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            checkMarkImage.alpha = 1.0
            doneButton.alpha = 1.0
            paymentSentLabel.textColor = .none
            paymentSentLabel.text = "Paid \(amount) \(denomination()) for a fee of \(fee) millisats ⚡️"
            paymentSentLabel.alpha = 1.0
            sendButton.removeFromSuperview()
            cancelButton.removeFromSuperview()
            recipientLabel.removeFromSuperview()
            memoLabel.removeFromSuperview()
            expiryLabel.removeFromSuperview()
            amountLabel.removeFromSuperview()
            expiryHeader.removeFromSuperview()
            descHeader.removeFromSuperview()
            recipientHeader.removeFromSuperview()
            amountHeader.removeFromSuperview()
            navigationItem.title = ""
            spinner.removeConnectingView()
            Vibration.success.vibrate()
        }
    }
    
    
    private func close() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
    private func load() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let amountMsat = invoice.amountMsat ?? invoice.invoiceAmountMsat ?? invoice.offerAmountMsat ?? userSpecifiedAmount else {
                showAlert(vc: self, title: "", message: "No amount specified.")
                return
            }
            
            switch denomination() {
            case "BTC":
                let btcAmount = amountMsat.msatToBtc
                self.amountLabel.text = btcAmount + " btc"
                
            case "SATS":
                let satsAmount = amountMsat.msatToSat
                self.amountLabel.text = satsAmount + " sats"
                
            default:
                if let fiatAmount = amountMsat.msatToFiat {
                    self.amountLabel.text = fiatAmount
                }
            }
            
            var expiry = ""
            if let validUntil = invoice.expiry, let createdAt = invoice.createdAt {
                let expiryInt = validUntil + createdAt
                expiry = convertedDate(seconds: expiryInt)
            } else if let absoluteExpiry = invoice.offerAbsoluteExpiry {
                expiry = convertedDate(seconds: absoluteExpiry)
            }
            
            self.expiryLabel.text = expiry
            self.memoLabel.text = invoice.description ?? invoice.offerDescription ?? "No description."
            self.recipientLabel.text = invoice.payee ?? invoice.offerNodeID ?? "Error fetching recipient."
            self.sendButton.alpha = 1
            self.amountLabel.alpha = 1
            self.recipientLabel.alpha = 1
            self.expiryLabel.alpha = 1
            self.memoLabel.alpha = 1
            self.spinner.removeConnectingView()
        }
    }
    
    
    private func denomination() -> String {
        return UserDefaults.standard.object(forKey: "denomination") as? String ?? "BTC"
    }
    
    
    private func convertedDate(seconds: Int) -> String {
        let date = Date(timeIntervalSince1970: Double(seconds))
        return date.displayDate
    }

    
}
