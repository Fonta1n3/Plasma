//
//  NodeDetailViewController.swift
//  BitSense
//
//  Created by Peter on 16/04/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import UIKit

class NodeDetailViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    
    let spinner = ConnectingView()
    var selectedNode:[String:Any]?
    let cd = CoreDataService()
    var createNew = Bool()
    var newNode = [String:Any]()
    var isInitialLoad = Bool()
    var lnlink = ""

    
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var nodeIdField: UITextField!
    @IBOutlet weak var scanQROutlet: UIBarButtonItem!
    @IBOutlet weak var nodeLabel: UITextField!
    @IBOutlet weak var rpcLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var exportNodeOutlet: UIBarButtonItem!
    @IBOutlet weak var runeField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        configureTapGesture()
        nodeLabel.delegate = self
        runeField.delegate = self
        addressField.delegate = self
        portField.delegate = self
        runeField.isSecureTextEntry = true
        saveButton.clipsToBounds = true
        saveButton.layer.cornerRadius = 8
        navigationController?.delegate = self
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        loadValues()
    }
    
    
    @IBAction func showLnlinkInfo(_ sender: Any) {
        guard let url = URL(string: "http://lnlink.app/qr") else { return }
        UIApplication.shared.open(url)
    }
    
    
    @IBAction func shareAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let address = addressField.text ?? ""
            let port = portField.text ?? ""
            let host = address + ":" + port
            let nodeId = nodeIdField.text ?? ""
            let rune = runeField.text ?? ""
            let base64UrlSafe = base64ToBase64url(base64: rune)
            guard let url = URL(string: "lnlink:" + nodeId + "@" + host + "?token=" + base64UrlSafe) else {
                showAlert(vc: self, title: "", message: "Invalid url string.")
                return
            }
            lnlink = url.absoluteString
            performSegue(withIdentifier: "segueToExportNode", sender: self)
        }
    }
        
    
    @IBAction func pasteAction(_ sender: Any) {
        guard let url = UIPasteboard.general.string else {
            showAlert(vc: self, title: "", message: "No text on clipboard.")
            return
        }
        
        QuickConnect.addNode(urlString: url) { [weak self] (node, errorMessage) in
            guard let self = self else { return }
            
            guard let node = node else {
                showAlert(vc: self, title: "", message: errorMessage ?? "Unknown error.")
                return
            }
            
            populateFields(node: node)
        }
    }
    
    
    @IBAction func scanQrAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            performSegue(withIdentifier: "segueToScanNodeCreds", sender: self)
        }
    }
    
    
    @IBAction func save(_ sender: Any) {
        func encryptedValue(_ decryptedValue: Data) -> Data? {
            return Crypto.encrypt(decryptedValue)
        }
        
        if selectedNode == nil {
            guard let addressText = addressField.text, let rune = runeField.text, let nodeId = nodeIdField.text, let port = portField.text, let label = nodeLabel.text else {
                showAlert(vc: self, title: "", message: "All fields need to be filled out.")
                return
            }
            
            guard let encAddress = encryptedValue(addressText.utf8)  else {
                showAlert(vc: self, title: "", message: "Error encrypting the address.")
                return
            }
            
            guard let encRune = encryptedValue(rune.utf8) else {
                showAlert(vc: self, title: "", message: "Error encrypting the rune.")
                return
            }
            
            guard let encNodeId = encryptedValue(nodeId.utf8) else {
                showAlert(vc: self, title: "", message: "Error encrypting the node ID.")
                return
            }
            
            newNode["id"] = UUID()
            newNode["label"] = label
            newNode["address"] = encAddress
            newNode["rune"] = encRune
            newNode["nodeId"] = encNodeId
            newNode["port"] = port
            
            CoreDataService.retrieveEntity(entityName: .nodes) { [weak self] nodes in
                guard let self = self else { return }
                
                guard let nodes = nodes else {
                    return
                }
                
                newNode["isActive"] = nodes.count == 0
                
                CoreDataService.saveEntity(dict: newNode, entityName: .nodes) { [weak self] success in
                    guard let self = self else { return }
                    
                    if success {
                        nodeAddedSuccess()
                    } else {
                        displayAlert(viewController: self, isError: true, message: "Error saving node.")
                    }
                }
            }
            
        } else {
            guard let node = selectedNode else { return }
            
            let id = node["id"] as! UUID
            
            if nodeLabel.text != "" {
                CoreDataService.update(id: id, keyToUpdate: "label", newValue: nodeLabel.text!, entity: .nodes) { success in
                    if !success {
                        displayAlert(viewController: self, isError: true, message: "Error updating label.")
                    }
                }
            }
            
            if let rune = runeField.text {
                guard let enc = encryptedValue(rune.utf8) else {
                    showAlert(vc: self, title: "", message: "Error encrypting node rune.")
                    return
                }
                
                CoreDataService.update(id: id, keyToUpdate: "rune", newValue: enc, entity: .nodes) { [weak self] success in
                    guard let self = self else { return }
                    
                    if !success {
                        displayAlert(viewController: self, isError: true, message: "Error updating rune.")
                        return
                    }
                }
            }
            
            if let nodeId = nodeIdField.text {
                guard let enc = encryptedValue(nodeId.utf8) else {
                    showAlert(vc: self, title: "", message: "Error encrypting node ID.")
                    return
                }
                
                CoreDataService.update(id: id, keyToUpdate: "nodeId", newValue: enc, entity: .nodes) { [weak self] success in
                    guard let self = self else { return }
                    
                    if !success {
                        displayAlert(viewController: self, isError: true, message: "Error updating node ID.")
                        return
                    }
                }
            }
            
            if let port = portField.text {
                CoreDataService.update(id: id, keyToUpdate: "port", newValue: port, entity: .nodes) { [weak self] success in
                    guard let self = self else { return }
                    
                    if !success {
                        displayAlert(viewController: self, isError: true, message: "Error updating node port.")
                        return
                    }
                }
            }
            
            if let addressText = addressField.text {
                guard let enc = encryptedValue(addressText.utf8) else {
                    showAlert(vc: self, title: "", message: "Error encrypting node address.")
                    return
                }
                
                CoreDataService.update(id: id, keyToUpdate: "address", newValue: enc, entity: .nodes) { [weak self] success in
                    guard let self = self else { return }
                    
                    if success {
                        nodeAddedSuccess()
                    } else {
                        displayAlert(viewController: self, isError: true, message: "Error updating node!")
                    }
                }
            }
                        
            nodeAddedSuccess()
        }
    }
    
//    private func checkRune(rune: String?, id: String) {
//        guard let rune = rune else { return }
//        
//        let param: [String: String] = ["rune": rune, "nodeid": id]
//        
//        LightningRPC.sharedInstance.command(method: .checkrune, params: param) { (response, errorDesc) in
//            guard let response = response else {
//                showAlert(vc: self, title: "", message: errorDesc ?? "Unknown error.")
//                return
//            }
//            
//            print(response)
//            
//            // Display that rune is valid
//            // Create a rune with restirctions and test it against checkrune...
//            // Show user their rune status, if its reads only or not etc
//            
//            // If true show the option to get fine grained control over the rune.
//            // Show option to create new rune with stricter permissions if its wide open.
//        }
//    }
    
    func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
    }
    
    func loadValues() {
        func decryptedValue(_ encryptedValue: Data) -> String {
            guard let decrypted = Crypto.decrypt(encryptedValue) else { return "" }
            
            return decrypted.utf8String ?? ""
        }
        
        func decryptedNostr(_ encryptedValue: Data) -> String {
            guard let decrypted = Crypto.decrypt(encryptedValue) else { return "" }
            
            return decrypted.hexString
        }
        
        if selectedNode != nil {
            let node = NodeStruct(dictionary: selectedNode!)
            if node.id != nil {
                if node.label != "" {
                    nodeLabel.text = node.label
                }
                
                if let rune = node.rune {
                    runeField.text = decryptedValue(rune)
                    
                    if let nodeId = node.nodeId {
                        let decId = decryptedValue(nodeId)
                        nodeIdField.text = decId
                    }
                }
                                
                if let address = node.address {
                    addressField.text = decryptedValue(address)
                }
                
                portField.text = node.port
            }
        }
    }
    
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            addressField.resignFirstResponder()
            nodeLabel.resignFirstResponder()
            runeField.resignFirstResponder()
            portField.resignFirstResponder()
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    
    private func nodeAddedSuccess() {
        if selectedNode == nil {
            selectedNode = newNode
            createNew = false
            showAlert(vc: self, title: "", message: "Node saved ✓")
        } else {
            showAlert(vc: self, title: "", message: "Node updated ✓")
        }
    }
    
    
    private func populateFields(node: NodeStruct) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            nodeLabel.text = node.label
            nodeIdField.text = node.nodeId!.utf8String!
            runeField.text = node.rune!.utf8String!
            portField.text = node.port
            addressField.text = node.address!.utf8String!
        }
    }
    
    
    private func base64ToBase64url(base64: String) -> String {
        let base64url = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "%3D")
        return base64url
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToScanNodeCreds" {
            guard let vc = segue.destination as? QRScannerViewController else { return }
            
            vc.isQuickConnect = true
            
            vc.onLNLinkDoneBlock = { [weak self] node in
                guard let self = self else { return }
                guard let node = node else { return }
                populateFields(node: node)
            }
        }
        
        if segue.identifier == "segueToExportNode" {
            guard let vc = segue.destination as? QRDisplayerViewController else { return }
            
            vc.headerText = "LNLink \(nodeLabel.text ?? "")"
            vc.text = lnlink
        }
    }
}
