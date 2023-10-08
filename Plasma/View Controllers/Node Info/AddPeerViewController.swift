//
//  AddPeerViewController.swift
//  FullyNoded
//
//  Created by Peter on 06/08/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import UIKit

class AddPeerViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var acnNowOutlet: UIButton!
    
    let denomination = UserDefaults.standard.object(forKey: "denomination") as? String ?? "BTC"
    let spinner = ConnectingView()
    var psbt = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        amountField.delegate = self
        
        headerLabel.text = "Enter an amount in \(denomination) to commit to the channel."
        configureTapGesture()
    }
    
    @IBAction func pasteAction(_ sender: Any) {
        guard let amountText = amountField.text, let _ = Int(amountText) else {
            showAlert(vc: self, title: "Add a valid commitment amount", message: "")
            return
        }
        
        guard let uri = UIPasteboard.general.string else {
            showAlert(vc: self, title: "", message: "No text on your clipboard.")
            return
        }
        
        var id:String!
        var port:String?
        var ip:String!
        
        if uri.contains("@") {
            let arr = uri.split(separator: "@")
            
            guard arr.count > 0 else { return }
            
            let arr1 = "\(arr[1])".split(separator: ":")
            id = "\(arr[0])"
            ip = "\(arr1[0])"
            
            guard arr1.count > 0 else { return }
            
            if arr1.count >= 2 {
                port = "\(arr1[1])"
            }
            
            self.addChannel(id: id, ip: ip, port: port)
            
        } else {
            showAlert(vc: self, title: "Incomplete URI", message: "The URI must include an address.")
        }
    }
    
    
    @IBAction func scanNowAction(_ sender: Any) {
        guard let amountText = amountField.text, let _ = Int(amountText) else {
            spinner.removeConnectingView()
            showAlert(vc: self, title: "Add a valid commitment amount", message: "")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: "segueToScannerFromLightningManager", sender: self)
        }
    }
    
    func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard (_:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        amountField.resignFirstResponder()
    }
    
    private func addChannel(id: String, ip: String, port: String?) {
        spinner.addConnectingView(vc: self, description: "creating a channel...")
        
        guard let amountText = amountField.text, let amount = Int(amountText) else {
            spinner.removeConnectingView()
            showAlert(vc: self, title: "Invalid committment amount", message: "")
            return
        }
        
        openChannelCL(amount: amount, id: id, ip: ip, port: port)
    }
        
    private func openChannelCL(amount: Int, id: String, ip: String?, port: String?) {
        // fundchannel id amount
        var satoshiAmount = ""
        switch denomination {
        case "BTC":
            satoshiAmount = "\(Double(amount) * 100000000.0)"
        case "SATS":
            satoshiAmount = "\(amount)"
        default:
            if let fxRate = UserDefaults.standard.object(forKey: "fxRate") as? Double {
                satoshiAmount = "\(Int((Double(amount) / fxRate) * 100000000.0))"
            }
            
            
        }
        
        let params: [String: String] = ["id": id, "amount": "\(satoshiAmount)"]
        LightningRPC.sharedInstance.command(method: .fundchannel, params: params) { [weak self] (response, errorDesc) in
            guard let self = self else { return }
            
            guard let response = response as? [String: Any], let _ = response["txid"] else {
                spinner.removeConnectingView()
                showAlert(vc: self, title: "", message: errorDesc ?? "Unknown error creating channel.")
                return
            }
            
            spinner.removeConnectingView()
            showAlert(vc: self, title: "", message: "Channel created ✓")
        }
//        Lightning.connect(amount: amount, id: id, ip: ip, port: port) { [weak self] (result, errorMessage) in
//            guard let self = self else { return }
//
//            self.spinner.removeConnectingView()
//
//            guard let result = result else {
//                showAlert(vc: self, title: "There was an issue.", message: errorMessage ?? "Unknown error connecting and funding that peer/channel.")
//                return
//            }
//
//            if let success = result["success"] as? Bool {
//                if success {
//                    showAlert(vc: self, title: "Channel created ⚡️", message: "Channel commitment secured!")
//                } else {
//                    showAlert(vc: self, title: "There was an issue...", message: errorMessage ?? "Unknown error.")
//                }
//            } else if let psbt = result["psbt"] as? String {
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//
//                    self.psbt = psbt
//                    self.promptToExportPsbt(psbt)
//                }
//
//            } else if let rawTx = result["rawTx"] as? String {
//                DispatchQueue.main.async {
//                    UIPasteboard.general.string = rawTx
//                }
//
//                showAlert(vc: self, title: "Channel funding had an issue...", message: "The raw transaction has been copied to your clipboard. Error: \(errorMessage ?? "Unknown error. Try broadcasting the transaction manually. Go to active wallet and tap the send / broadcast button then tap paste.")")
//            }
//        }
    }
    
    private func promptToExportPsbt(_ psbt: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alertStyle = UIAlertController.Style.alert
            let tit = "Export PSBT"
            let mess = "⚠️ Warning!\n\nYou MUST broadcast the signed transaction with this device using Fully Noded! Otherwise there is a chance of loss of funds and channel funding WILL FAIL!"
            
            let alert = UIAlertController(title: tit, message: mess, preferredStyle: alertStyle)
            
            alert.addAction(UIAlertAction(title: "Export", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.exportPsbt()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func exportPsbt() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "segueToExportPsbtForChannelFunding", sender: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToScannerFromLightningManager" {
            if #available(macCatalyst 14.0, *) {
                if let vc = segue.destination as? QRScannerViewController {
                    vc.isScanningAddress = true
                    
                    vc.onDoneBlock = { [weak self] url in
                        guard let self = self else { return }
                        
                        guard let url = url else { return }
                        
                        var id:String!
                        var port:String?
                        var ip:String!
                        
                        if url.contains("@") {
                            let arr = url.split(separator: "@")
                            
                            guard arr.count > 0 else { return }
                            
                            let arr1 = "\(arr[1])".split(separator: ":")
                            id = "\(arr[0])"
                            ip = "\(arr1[0])"
                            
                            guard arr1.count > 0 else { return }
                            
                            if arr1.count >= 2 {
                                port = "\(arr1[1])"
                            }
                            
                            self.addChannel(id: id, ip: ip, port: port)
                            
                        } else {
                            self.spinner.removeConnectingView()
                            showAlert(vc: self, title: "Incomplete URI", message: "The URI must include an address.")
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
