//
//  SecurityCenterViewController.swift
//  BitSense
//
//  Created by Peter on 11/10/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import UIKit

class SecurityCenterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    let ud = UserDefaults.standard
    @IBOutlet var securityTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        securityTable.delegate = self
        securityTable.dataSource = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "securityCell", for: indexPath)
        cell.selectionStyle = .none
        let label = cell.viewWithTag(2) as! UILabel
        let icon = cell.viewWithTag(1) as! UIImageView
        
        switch indexPath.section {
       case 0:
            if KeyChain.getData("UnlockPassword") != nil {
                label.text = "Reset"
                icon.image = UIImage(systemName: "arrow.clockwise")
            } else {
                label.text = "Set"
                icon.image = UIImage(systemName: "plus")
            }
                                    
        case 1:
            if ud.object(forKey: "bioMetricsDisabled") != nil {
                label.text = "Disabled"
                label.textColor = .darkGray
                icon.image = UIImage(systemName: "eye.slash")
            } else {
                label.text = "Enabled"
                label.textColor = .none
                icon.image = UIImage(systemName: "eye")
            }
                                    
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 50)
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.textColor = .secondaryLabel
        textLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        switch section {
        case 0:
            textLabel.text = "App Password"
                        
        case 1:
            textLabel.text = "Biometrics"
                        
        default:
            break
        }
        header.addSubview(textLabel)
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            DispatchQueue.main.async { [unowned vc = self] in
                vc.performSegue(withIdentifier: "addPasswordSegue", sender: vc)
            }
            
        case 1:
            if ud.object(forKey: "bioMetricsDisabled") != nil {
                ud.removeObject(forKey: "bioMetricsDisabled")
            } else {
                ud.set(true, forKey: "bioMetricsDisabled")
            }
            DispatchQueue.main.async {
                tableView.reloadSections([1], with: .fade)
            }
            
        default:
            break
        }
    }
    
    private func exisitingPassword() -> Data? {
        return KeyChain.getData("UnlockPassword")
    }
    
    private func hash(_ text: String) -> Data? {
        return text.hex
    }
}
