//
//  NodesViewController.swift
//  BitSense
//
//  Created by Peter on 29/09/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import UIKit

class NodesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    var nodeArray = [[String:Any]]()
    var selectedIndex = Int()
    let ud = UserDefaults.standard
    var addButton = UIBarButtonItem()
    var editButton = UIBarButtonItem()
    @IBOutlet var nodeTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        nodeTable.tableFooterView = UIView(frame: .zero)
        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNode))
        editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editNodes))
        navigationItem.setRightBarButtonItems([addButton, editButton], animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getNodes()
    }
    
    func getNodes() {
        nodeArray.removeAll()
        
        CoreDataService.retrieveEntity(entityName: .nodes) { [weak self] nodes in
            guard let self = self else { return }
            
            guard let nodes = nodes else {
                displayAlert(viewController: self,
                             isError: true,
                             message: "error getting nodes from core data")
                return
            }
                        
            for node in nodes {
                let nodeStr = NodeStruct(dictionary: node)
                if nodeStr.id != nil {
                    self.nodeArray.append(node)
                }
            }
            
            self.reloadNodeTable()
            
            if self.nodeArray.count == 0 {
                showAlert(vc: self, title: "", message: "No nodes added yet, tap the + sign to add one.")
            }
        }
    }
    
    private func reloadNodeTable() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.nodeTable.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodeArray.count
    }
    
    private func decryptedValue(_ encryptedValue: Data) -> String {
        guard let decrypted = Crypto.decrypt(encryptedValue) else { return "" }
        
        return decrypted.utf8String ?? ""
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "node", for: indexPath)
        let label = cell.viewWithTag(1) as! UILabel
        let button = cell.viewWithTag(5) as! UIButton
        button.tintColor = .none
        button.restorationIdentifier = "\(indexPath.row)"
        button.addTarget(self, action: #selector(editNode(_:)), for: .touchUpInside)
        
        let nodeStruct = NodeStruct(dictionary: nodeArray[indexPath.row])
        
        label.text = nodeStruct.label
        
        if !nodeStruct.isActive {
            label.textColor = .secondaryLabel
            cell.accessoryType = .none
            cell.isSelected = false
        } else {
            label.textColor = .none
            cell.accessoryType = .checkmark
            cell.isSelected = true
            cell.accessoryView?.frame = .init(x: 0, y: 0, width: 35, height: 35)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    @objc func editNode(_ sender: UIButton) {
        guard let id = sender.restorationIdentifier, let section = Int(id) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.selectedIndex = section
            self.performSegue(withIdentifier: "updateNode", sender: self)
        }
    }
    
    @objc func editNodes() {
        nodeTable.setEditing(!nodeTable.isEditing, animated: true)
        
        if nodeTable.isEditing {
            editButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(editNodes))
        } else {
            editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editNodes))
        }
        
        self.navigationItem.setRightBarButtonItems([addButton, editButton], animated: true)
    }
    
    private func deleteNode(nodeId: UUID, indexPath: IndexPath) {
        CoreDataService.deleteEntity(id: nodeId, entityName: .nodes) { [unowned vc = self] success in
            if success {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.nodeArray.remove(at: indexPath.row)
                    vc.nodeTable.deleteRows(at: [indexPath], with: .fade)
                }
            } else {
                displayAlert(viewController: vc,
                             isError: true,
                             message: "We had an error trying to delete that node")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            let node = NodeStruct(dictionary: nodeArray[indexPath.row])
            if node.id != nil {
                deleteNode(nodeId: node.id!, indexPath: indexPath)
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nodeStr = NodeStruct(dictionary: nodeArray[indexPath.row])
        
        CoreDataService.update(id: nodeStr.id!, keyToUpdate: "isActive", newValue: true, entity: .nodes) { [weak self] success in
            guard let self = self else { return }
                                    
            if success {
                if nodeArray.count == 1 {
                    reloadTable()
                } else {
                    for (i, node) in nodeArray.enumerated() {
                        
                        func finish() {
                            if i + 1 == self.nodeArray.count {
                                CoreDataService.retrieveEntity(entityName: .nodes) { nodes in
                                    if nodes != nil {
                                        DispatchQueue.main.async { [unowned vc = self] in
                                            vc.nodeArray.removeAll()
                                            for (x, node) in nodes!.enumerated() {
                                                let str = NodeStruct(dictionary: node)
                                                if str.id != nil {
                                                    vc.nodeArray.append(node)
                                                }
                                                if x + 1 == nodes!.count {
                                                    vc.nodeTable.reloadData()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if i != indexPath.row {
                            let str = NodeStruct(dictionary: node)
                                CoreDataService.update(id: str.id!, keyToUpdate: "isActive", newValue: false, entity: .nodes) { updated in
                                    print("node updated: \(updated)")
                                    
                                    finish()
                                }
                        } else {
                            finish()
                        }
                    }
                }
            } else {
                showAlert(vc: self, title: "", message: "Error updating node.")
            }
        }
    }
    
    
    func reloadTable() {
        CoreDataService.retrieveEntity(entityName: .nodes) { nodes in
            if nodes != nil {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.nodeArray.removeAll()
                    for node in nodes! {
                        let ns = NodeStruct(dictionary: node)
                        if ns.id != nil {
                            vc.nodeArray.append(node)
                        }
                    }
                    vc.nodeTable.reloadData()
                }
            } else {
                
                displayAlert(viewController: self,
                             isError: true,
                             message: "error getting nodes from core data")
            }
        }
    }
    
    private func reduced(label: String) -> String {
        var first = String(label.prefix(25))
        if label.count > 25 {
            first += "..."
        }
        return "\(first)"
    }
    
    @IBAction func addNode(_ sender: Any) {
        segueToAddNodeManually()
    }
        
    private func segueToAddNodeManually() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToAddLightningNode", sender: vc)
        }
    }
    
//    private func segueToScanNode() {
//        DispatchQueue.main.async { [unowned vc = self] in
//            vc.performSegue(withIdentifier: "segueToScanAddNode", sender: vc)
//        }
//    }
    
//    private func addBtcRpcQr(url: String) {
//        QuickConnect.addNode(uncleJim: false, url: url) { [weak self] (success, errorMessage) in
//            if success {
//                if !url.hasPrefix("clightning-rpc") && !url.hasPrefix("lndconnect:") && !url.hasPrefix("http") {
//                    DispatchQueue.main.async { [weak self] in
//                        guard let self = self else { return }
//
//                        NotificationCenter.default.post(name: .refreshNode, object: nil, userInfo: nil)
//                        self.tabBarController?.selectedIndex = 0
//                    }
//                } else {
//                    self?.reloadTable()
//                }
//            } else {
//                displayAlert(viewController: self, isError: true, message: "Error adding that node: \(errorMessage ?? "unknown")")
//            }
//        }
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "updateNode" {
            if let vc = segue.destination as? NodeDetailViewController {
                vc.selectedNode = self.nodeArray[selectedIndex]
                vc.createNew = false
            }
        }
        
        if segue.identifier == "segueToAddLightningNode" {
            if let vc = segue.destination as? NodeDetailViewController {
                vc.createNew = true
            }
        }
        
//        if segue.identifier == "segueToScanAddNode" {
//            if #available(macCatalyst 14.0, *) {
//                if let vc = segue.destination as? QRScannerViewController {
//                    vc.isQuickConnect = true
//                    vc.onDoneBlock = { [unowned thisVc = self] url in
//                        if url != nil {
//                            thisVc.addBtcRpcQr(url: url!)
//                        }
//                    }
//                }
//            } else {
//                // Fallback on earlier versions
//            }
//        }
        
    }
}
