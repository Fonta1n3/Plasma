//
//  ConfirmLightningPaymentViewController.swift
//  FullyNoded
//
//  Created by Peter Denton on 7/11/21.
//  Copyright © 2021 Fontaine. All rights reserved.
//

import UIKit

class ConfirmLightningPaymentViewController: UIViewController {
    
    var doneBlock:(((Bool)) -> Void)?
    var fxRate:Double?
    var invoice: DecodedInvoice!
    var spinner = ConnectingView()
    var userSpecifiedAmount: Int?
    
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var recipientLabel: UILabel!
    @IBOutlet weak var expiryLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var memoLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        spinner.addConnectingView(vc: self, description: "")
        amountLabel.alpha = 0
        recipientLabel.alpha = 0
        expiryLabel.alpha = 0
        sendButton.alpha = 0
        sendButton.layer.cornerRadius = 8
        sendButton.clipsToBounds = true
        load()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        close(confirmed: false)
    }
    
    @IBAction func closeAction(_ sender: Any) {
        close(confirmed: false)
    }
    
    @IBAction func sendAction(_ sender: Any) {
        close(confirmed: true)
    }
    
    private func close(confirmed: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.doneBlock!(confirmed)
            self.dismiss(animated: true, completion: nil)
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
            if let validUntil = invoice.expiry {
                let expiryInt = validUntil
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
