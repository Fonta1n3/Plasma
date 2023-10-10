//
//  WalletViewController.swift
//  FullyNoded
//
//  Created by Peter Denton on 10/1/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

import UIKit

class WalletViewController: UIViewController {
    
    
    let spinner = UIActivityIndicatorView(style: .medium)
    var refreshButton = UIBarButtonItem()
    var dataRefresher = UIBarButtonItem()
    var addr = ""
    var withdrawing = false
    var paying = false
    var isUnlocked = false
    var showOnchain = false
    var showOffchain = false
    var onchainAmountAvailable = ""
    var fxRate: Double?
    var onchainTxs: [Output] = []
    var initialLoad = true
    
    @IBOutlet weak var fxRateLabel: UILabel!
    @IBOutlet weak var balanceBackgroundView: UIView!
    @IBOutlet weak var onchainBackgroundView: UIView!
    @IBOutlet weak var offchainBackgroundView: UIView!
    @IBOutlet weak var totalBalanceLabel: UILabel!
    @IBOutlet weak var onchainBalanceLabel: UILabel!
    @IBOutlet weak var offchainBalanceLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if !firstTimeHere() {
            showAlert(vc: self, title: "", message: "Critical error setting our encryption key.")
        }
        setIcon()
        configureView(balanceBackgroundView)
        configureView(onchainBackgroundView)
        configureView(offchainBackgroundView)
        if initialLoad {
            addNavBarSpinner()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        withdrawing = false
        paying = false
        showOnchain = false
        showOffchain = false
        addr = ""
        
        checkForLightningNodes { [weak self] node in
            guard let self = self else { return }
            
            guard let node = node else {
                removeLoader()
                promptToAddNode()
                
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                navigationItem.title = node.label
            }
            
            if initialLoad {
                if KeyChain.getData("UnlockPassword") != nil {
                    if isUnlocked {
                        loadData()
                    } else {
                        showUnlockScreen()
                    }
                } else {
                    loadData()
                }
                initialLoad = false
            }
        }
    }
    
    
    private func setIcon() {
        let appIcon = UIButton(type: .custom)
        appIcon.setImage(UIImage(named: "plasma_icon.png"), for: .normal)
        appIcon.imageView?.layer.cornerRadius = 18
        appIcon.imageView?.clipsToBounds = true
        appIcon.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        appIcon.imageView?.contentMode = .scaleAspectFit
        appIcon.translatesAutoresizingMaskIntoConstraints = false
        appIcon.widthAnchor.constraint(equalToConstant: 35).isActive = true
        appIcon.heightAnchor.constraint(equalToConstant: 35).isActive = true
        let leftBarButton = UIBarButtonItem(customView: appIcon)
        navigationItem.leftBarButtonItem = leftBarButton
    }
    
    
    private func showTxs() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            performSegue(withIdentifier: "segueToTransactions", sender: self)
        }
    }
    
    
    @IBAction func showOnchainTxsAction(_ sender: Any) {
        showOnchain = true
        showTxs()
    }
    
    @IBAction func showOffchainTxsAction(_ sender: Any) {
        showOffchain = true
        showTxs()
    }
    
    
    @IBAction func depositAction(_ sender: Any) {
        addNavBarSpinner()
        LightningRPC.sharedInstance.command(method: .newaddr, params: ["addresstype":"all"]) { [weak self] (newaddr, errorDesc) in
            guard let self = self else { return }
            guard let newaddr = newaddr as? NewAddr else {
                removeLoader()
                showAlert(vc: self, title: "", message: errorDesc ?? "Uknown error fetching deposit address.")
                return
            }
            
            removeLoader()
            
            DispatchQueue.main.async { [unowned vc = self] in
                let title = "Address type?"
                let message = "Select an address format."
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                let bech32 = UIAlertAction(title: "Segwit (bech32)", style: .default) { [weak self] alertAction in
                    guard let self = self else { return }
                    addr = newaddr.bech32
                    showAddress()
                }
                let p2tr = UIAlertAction(title: "Taproot (p2tr)", style: .default) { [weak self] alertAction in
                    guard let self = self else { return }
                    addr = newaddr.p2tr
                    showAddress()
                }
                alert.addAction(bech32)
                alert.addAction(p2tr)
                let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in }
                alert.addAction(cancel)
                vc.present(alert, animated:true, completion: nil)
            }
        }
    }
    
    @IBAction func payAction(_ sender: Any) {
        paying = true
        goSend()
    }
    
    @IBAction func withdrawAction(_ sender: Any) {
        withdrawing = true
        goSend()
    }
    
    
    private func goSend() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "segueToSend", sender: self)
        }
    }
    
    
    
    private func showAddress() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "segueToShowAddress", sender: self)
        }
    }
    
    
    private func configureView(_ view: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let _ = self else { return }
            
            view.clipsToBounds = true
            view.layer.cornerRadius = 8
        }
    }
    
    
    private func addNavBarSpinner() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            spinner.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            dataRefresher = UIBarButtonItem(customView: spinner)
            navigationItem.setRightBarButton(dataRefresher, animated: true)
            spinner.startAnimating()
            spinner.alpha = 1
        }
    }
    
    
    private func removeLoader() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            spinner.stopAnimating()
            spinner.alpha = 0
            refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshData(_:)))
            navigationItem.setRightBarButton(refreshButton, animated: true)
        }
    }
    
    
    @objc func refreshData(_ sender: Any) {
        addNavBarSpinner()
        listFunds()
    }
    
    
    private func promptToAddNode() {
        DispatchQueue.main.async { [unowned vc = self] in
            let title = "Add a node?"
            let message = "You need to add a Core Lightning node first."
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let addNode = UIAlertAction(title: "Add a node", style: .default) { (alertAction) in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    performSegue(withIdentifier: "segueToAddANode", sender: self)
                }
            }
            alert.addAction(addNode)
            let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in }
            alert.addAction(cancel)
            vc.present(alert, animated:true, completion: nil)
        }
    }
    
    
    private func checkForLightningNodes(completion: @escaping ((NodeStruct?)) -> Void) {
        CoreDataService.retrieveEntity(entityName: .nodes) { nodes in
            guard let nodes = nodes, nodes.count > 0 else {
                completion(nil)
                return
            }
            
            var lightningNode:NodeStruct?
            
            for (i, node) in nodes.enumerated() {
                let ns = NodeStruct(dictionary: node)
                
                if ns.isActive {
                    lightningNode = ns
                }
                
                if i + 1 == nodes.count {
                    completion(lightningNode)
                }
            }
        }
    }
    
    
    private func loadData() {
        if !initialLoad {
            addNavBarSpinner()
        }
        listFunds()
    }
    
    
    private func listFunds() {
        FetchFunds.sharedInstance.balancesAndTxs { [weak self] (balances, txs, errorMessage) in
            guard let self = self else { return }
            
            guard errorMessage == nil else {
                removeLoader()
                showAlert(vc: self, title: "", message: errorMessage!)
                return
            }
            
            guard let balances = balances else {
                removeLoader()
                showAlert(vc: self, title: "", message: errorMessage ?? "Unknown error listfunds.")
                return
            }
                        
            updateViews(balances: balances)
            onchainTxs = txs
            
            FiatConverter.sharedInstance.getFxRate { [weak self] fxRate in
                guard let self = self else { return }
                guard let fxRate = fxRate else {
                    showAlert(vc: self, title: "", message: "Unable to fetch the exchange rate.")
                    return
                }
                
                self.fxRate = fxRate
                DispatchQueue.main.async { [weak self] in
                    self?.fxRateLabel.text = "\(fxRate.fiatString) / btc"
                }
                updateViews(balances: balances)
            }
        }
    }
    
    
    private func updateViews(balances: Balances) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            onchainAmountAvailable = balances.onchainBalance
            totalBalanceLabel.text = balances.totalBalance
            onchainBalanceLabel.text = onchainAmountAvailable
            offchainBalanceLabel.text = balances.offchainBalance
            removeLoader()
        }
    }
    

    private func firstTimeHere() -> Bool {
        return FirstTime.firstTimeHere()
    }
    
    
    private func showUnlockScreen() {
        if KeyChain.getData("UnlockPassword") != nil {
            DispatchQueue.main.async { [weak self] in
                self?.performSegue(withIdentifier: "lockScreen", sender: self)
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "segueToShowAddress":
            guard let vc = segue.destination as? QRDisplayerViewController else { fallthrough }
            
            vc.text = addr
            vc.headerText = "Deposit Address"
            
        case "segueToSend":
            guard let vc = segue.destination as? CreateRawTxViewController else { fallthrough }
            
            vc.withdrawing = withdrawing
            vc.paying = paying
            vc.onchainAmountAvailable = onchainAmountAvailable
            
        case "lockScreen":
            guard let vc = segue.destination as? LogInViewController else { fallthrough }
            
            vc.onDoneBlock = { [weak self] in
                guard let self = self else { return }
                
                isUnlocked = true
                loadData()
            }
            
        case "segueToTransactions":
            guard let vc = segue.destination as? ActiveWalletViewController else { fallthrough }
            
            vc.fxRate = fxRate
            vc.onchainTxs = onchainTxs
            vc.showOnchain = showOnchain
            vc.showOffchain = showOffchain
        default:
            break
            
        }
    }

}
