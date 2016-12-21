/* Copyright (c) 2016 Håvard Fossli
 * Copyright (c) 2016 Trail of Bits, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var inputLabel: UITextField!
    @IBOutlet weak var signatureLabel: UITextField!
    @IBOutlet weak var publicKeyLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            let publicKey = try Manager.shared.publicKey()
            publicKeyLabel.text = publicKey
            print("Public key \(publicKey)")
        } catch let error {
            print("Error \(error)")
            publicKeyLabel.text = "Error occured. See console."
        }
    }
    
    @IBAction func sign(_ sender: Any) {
        do {
            let input = inputLabel.text?.data(using: .utf8) ?? Data()
            let signature = try Manager.shared.sign(input)
            let signatureAsHex = signature.map { String(format: "%02hhx", $0) }.joined()
            signatureLabel.text = signatureAsHex
            print("Signature \(signatureAsHex)")
        } catch let error {
            print("Error \(error)")
            signatureLabel.text = "Error occured. See console."
        }
    }

    @IBAction func regenerateKeypair(_ sender: Any) {
        do {
            try Manager.shared.deleteKeyPair()
            let publicKey = try Manager.shared.publicKey()
            publicKeyLabel.text = publicKey
            print("Recreated public key \(publicKey)")
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

