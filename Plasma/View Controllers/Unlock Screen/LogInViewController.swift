//
//  LogInViewController.swift
//  BitSense
//
//  Created by Peter on 03/09/18.
//  Copyright © 2018 Fontaine. All rights reserved.
//

import UIKit
import LocalAuthentication

class LogInViewController: UIViewController, UITextFieldDelegate {

    var onDoneBlock: (() -> Void)?
    let nextButton = UIButton()
    var timeToDisable = 2.0
    var timer: Timer?
    var secondsRemaining = 2
    var tapGesture:UITapGestureRecognizer!
    var isRessetting = false
    var initialLoad = true
    
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var nextAttemptLabel: UILabel!
    @IBOutlet weak var touchIdButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)

        passwordField.delegate = self
        passwordField.returnKeyType = .done
        passwordField.keyboardType = .default
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.placeholder = "password"
        passwordField.isSecureTextEntry = true
        passwordField.returnKeyType = .go
        passwordField.textAlignment = .center
        passwordField.keyboardAppearance = .dark
        
        resetButton.alpha = 0

        #if !targetEnvironment(macCatalyst)
        touchIdButton.alpha = 1
        #else
        touchIdButton.alpha = 0
        #endif


        guard let timeToDisableOnKeychain = KeyChain.getData("TimeToDisable") else {
            let _ = KeyChain.set("2.0".utf8, forKey: "TimeToDisable")
            return
        }

        guard let seconds = timeToDisableOnKeychain.utf8String, let time = Double(seconds) else { return }

        timeToDisable = time
        secondsRemaining = Int(timeToDisable)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if initialLoad {
            initialLoad = false
            passwordField.removeGestureRecognizer(tapGesture)

            let ud = UserDefaults.standard

            if ud.object(forKey: "bioMetricsDisabled") == nil {
                touchIdButton.alpha = 1
                authenticationWithTouchID()
            }

            if timeToDisable > 2.0 {
                disable()
            }
        }
    }
    
    
    @IBAction func faceIdAction(_ sender: Any) {
        authenticationWithTouchID()
    }
    
    
    @IBAction func resetAction(_ sender: Any) {
        promptToReset()
    }
    
    
    private func addResetPassword() {
        resetButton.alpha = 1
    }

    
    @objc func promptToReset() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "⚠️ Reset app password?",
                                          message: "THIS DELETES ALL DATA AND COMPLETELY WIPES THE APP! Force quit the app and reopen the app after this action.",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.destroy { destroyed in
                    if destroyed {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            
                            KeyChain.removeAll()
                            self.timeToDisable = 0.0
                            self.timer?.invalidate()
                            self.secondsRemaining = 0
                            self.dismiss(animated: true) {
                                showAlert(vc: self, title: "", message: "The app has been wiped.")
                                self.onDoneBlock!()
                            }
                        }
                    } else {
                        showAlert(vc: self, title: "", message: "The app was not wiped!")
                    }
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true) {}
        }
    }
    
    private func destroy(completion: @escaping ((Bool)) -> Void) {
        CoreDataService.deleteAllData(entity: .nodes) { success in
            completion((success))
        }
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.passwordField.resignFirstResponder()
        }
    }

    @IBAction func unlocAction(_ sender: Any) {
        guard passwordField.text != "" else {
            shakeAlert(viewToShake: passwordField)
            return
        }

        passwordField.resignFirstResponder()
        checkPassword(password: passwordField.text!)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard passwordField.text != "" else {
            shakeAlert(viewToShake: passwordField)
            return true
        }
        
        checkPassword(password: passwordField.text!)
        return true
    }

    private func unlock() {
        let _ = KeyChain.set("2.0".utf8, forKey: "TimeToDisable")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.touchIdButton.removeFromSuperview()
            self.nextButton.removeFromSuperview()
            
            UIView.animate(withDuration: 0.2, animations: {
                self.passwordField.alpha = 0
                
            }, completion: { _ in
                self.passwordField.text = ""
                self.passwordField.removeFromSuperview()
                
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.onDoneBlock!()
                    }
                }
            })
        }
    }

    func checkPassword(password: String) {
        guard let passwordData = KeyChain.getData("UnlockPassword") else { return }

        let retrievedPassword = passwordData.utf8String

        let hashedPassword = Crypto.sha256hash(password)

        guard let hexData = hashedPassword.hex else { return }

        if password == retrievedPassword {
            let _ = KeyChain.set(hexData, forKey: "UnlockPassword")
            unlock()

        } else {
            if hexData.hexString == passwordData.hexString {
                unlock()

            } else {
                timeToDisable = timeToDisable * 2.0
                
                if timeToDisable > 4.0 {
                    addResetPassword()
                }

                guard KeyChain.set("\(timeToDisable)".utf8, forKey: "TimeToDisable") else {
                    showAlert(vc: self, title: "Unable to set timeout", message: "This means something is very wrong, the device has probably been jailbroken or is corrupted")
                    return
                }

                secondsRemaining = Int(timeToDisable)

                disable()
            }
        }
    }


    private func disable() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            passwordField.alpha = 0
            passwordField.isUserInteractionEnabled = false
            nextButton.alpha = 0
        }

        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if self.secondsRemaining == 0 {
                    self.timer?.invalidate()
                    self.nextAttemptLabel.text = ""
                    self.nextButton.alpha = 1
                    self.passwordField.alpha = 1
                    self.passwordField.isUserInteractionEnabled = true
                } else {
                    self.secondsRemaining -= 1
                    self.nextAttemptLabel.text = "Try again in \(self.secondsRemaining) seconds."
                }
            }
        }

        showAlert(vc: self, title: "Wrong password", message: "")
    }
    
    @objc func authenticationWithTouchID() {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = "Use passcode"
        var authError: NSError?
        let reasonString = "To unlock"

        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reasonString) { success, evaluateError in
                if success {
                    DispatchQueue.main.async {
                        self.unlock()
                    }
                } else {
                    guard let error = evaluateError else { return }

                    print(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code))
                }
            }

        } else {

            guard let error = authError else { return }

            //TODO: Show appropriate alert if biometry/TouchID/FaceID is lockout or not enrolled
            if self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code) != "Too many failed attempts." {

            }
        }
    }

    func evaluatePolicyFailErrorMessageForLA(errorCode: Int) -> String {
        var message = ""

        if #available(iOS 11.0, macOS 10.13, *) {

            switch errorCode {

            case LAError.biometryNotAvailable.rawValue:
                message = "Authentication could not start because the device does not support biometric authentication."

            case LAError.biometryLockout.rawValue:
                message = "Authentication could not continue because the user has been locked out of biometric authentication, due to failing authentication too many times."

            case LAError.biometryNotEnrolled.rawValue:
                message = "Authentication could not start because the user has not enrolled in biometric authentication."

            default:
                message = "Did not find error code on LAError object"
            }

        } else {

            switch errorCode {

            case LAError.touchIDLockout.rawValue:
                message = "Too many failed attempts."

            case LAError.touchIDNotAvailable.rawValue:
                message = "TouchID is not available on the device"

            case LAError.touchIDNotEnrolled.rawValue:
                message = "TouchID is not enrolled on the device"

            default:
                message = "Did not find error code on LAError object"
            }

        }

        return message

    }

    func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
        var message = ""

        switch errorCode {
        case LAError.authenticationFailed.rawValue:
            message = "The user failed to provide valid credentials"

        case LAError.appCancel.rawValue:
            message = "Authentication was cancelled by application"

        case LAError.invalidContext.rawValue:
            message = "The context is invalid"

        case LAError.notInteractive.rawValue:
            message = "Not interactive"

        case LAError.passcodeNotSet.rawValue:
            message = "Passcode is not set on the device"

        case LAError.systemCancel.rawValue:
            message = "Authentication was cancelled by the system"

        case LAError.userCancel.rawValue:
            message = "The user did cancel"

        case LAError.userFallback.rawValue:
            message = "The user chose to use the fallback"

        default:
            message = evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
        }

        return message
    }
}

extension UIViewController {

    func topViewController() -> UIViewController! {
        if self.isKind(of: UITabBarController.self) {
            let tabbarController =  self as! UITabBarController
            return tabbarController.selectedViewController!.topViewController()
        } else if (self.isKind(of: UINavigationController.self)) {
            let navigationController = self as! UINavigationController
            return navigationController.visibleViewController!.topViewController()
        } else if ((self.presentedViewController) != nil) {
            let controller = self.presentedViewController
            return controller!.topViewController()
        } else {
            return self
        }
    }

}
