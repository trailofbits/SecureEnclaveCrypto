//
//  ViewController.swift
//  SecureEnclaveDemo
//
//  Created by Håvard Fossli on 14.11.2016.
//  Copyright © 2016 Ages. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var inputLabel: UITextField!
    @IBOutlet weak var signatureLabel: UITextField!
    @IBOutlet weak var publicKeyLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            publicKeyLabel.text = try SecureEnclaveManager.shared.publicKey()
        } catch let error {
            print("Error \(error)")
            publicKeyLabel.text = "Error occured. See console."
        }
    }
    
    @IBAction func sign(_ sender: Any) {
        do {
            let input = inputLabel.text?.data(using: .utf8) ?? Data()
            let result = try SecureEnclaveManager.shared.sign(input)
            signatureLabel.text = result.map { String(format: "%02hhx", $0) }.joined()
        } catch let error {
            print("Error \(error)")
            signatureLabel.text = "Error occured. See console."
        }
    }

    @IBAction func regenerateKeypair(_ sender: Any) {
        do {
            try SecureEnclaveManager.shared.deleteKeyPair()
            publicKeyLabel.text = try SecureEnclaveManager.shared.publicKey()
        } catch let error {
            print("Error \(error)")
            publicKeyLabel.text = "Error occured. See console."
        }
    }
    
    @IBAction func signWithDelay(_ sender: Any) {
        let task = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.sign(sender)
            UIApplication.shared.endBackgroundTask(task)
        }
    }
}

