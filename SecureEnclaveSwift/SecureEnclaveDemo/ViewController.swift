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
    
    var publicKey = ""

    @IBOutlet weak var publicKeyTextField: UITextField!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var signatureTextField: UITextField!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    @IBAction func generateKeypair(_ sender: Any) {
        
        do {
            
            if !publicKey.isEmpty {
                try Manager.shared.deleteKeyPair()
            }
            
            publicKey = try Manager.shared.publicKey()
            publicKeyTextField.text = publicKey
            print("Public key \(publicKey)")
        }
        catch let error {
            
            let errorHelper = error as! SecureEnclaveHelperError
            showErrorCode(link: errorHelper.link)
            
            print("Error \(error)")
        }
    }
    
    @IBAction func sign(_ sender: Any) {
        
        do {
            
            let input = inputTextField.text?.data(using: .utf8) ?? Data()
            let signature = try Manager.shared.sign(input)
            let signatureAsHex = signature.map { String(format: "%02hhx", $0) }.joined()
            signatureTextField.text = signatureAsHex
            print("Signature \(signatureAsHex)")
        }
        catch let error {
            
            let errorHelper = error as! SecureEnclaveHelperError
            showErrorCode(link: errorHelper.link)
            
            print("Error \(error)")
            signatureTextField.text = ""
        }
    }

    @IBAction func signWithDelay(_ sender: Any) {
        
        let task = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            
            self.sign(sender)
            UIApplication.shared.endBackgroundTask(task)
        }
    }
    
    func showErrorCode(link: String) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ErrorViewController") as! ErrorViewController
        vc.url = link
        self.present(vc, animated: true, completion: nil)
    }
}

