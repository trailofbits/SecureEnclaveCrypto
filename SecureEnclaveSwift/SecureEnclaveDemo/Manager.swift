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

import Foundation

final class Manager {
    
    static let shared = Manager()
    private init() {}
    
    private let helper = SecureEnclaveHelper(publicLabel: "no.agens.demo.publicKey", privateLabel: "no.agens.demo.privateKey", operationPrompt: "Authenticate to continue")
    
    func deleteKeyPair() throws {
        try helper.deletePublicKey()
        try helper.deletePrivateKey()
    }
    
    func publicKey() throws -> String {
        let keys = try getKeys()
        return keys.public.hex
    }
    
    func verify(signature: Data, originalDigest: Data) throws -> Bool {
        let keys = try getKeys()
        return try helper.verify(signature: signature, digest: originalDigest, publicKey: keys.public.ref)
    }
    
    func sign(_ digest: Data) throws -> Data {
        let keys = try getKeys()
        let signed = try helper.sign(digest, privateKey: keys.private)
        return signed
    }
    
    @available(iOS 10.3, *)
    func encrypt(_ data: Data) throws -> Data {
        let keys = try getKeys()
        let signed = try helper.encrypt(data, publicKey: keys.public.ref)
        return signed
    }
    
    @available(iOS 10.3, *)
    func decrypt(_ data: Data) throws -> Data {
        let keys = try getKeys()
        let signed = try helper.decrypt(data, privateKey: keys.private)
        return signed
    }
    
    private func getKeys() throws -> (`public`: SecureEnclaveKeyData, `private`: SecureEnclaveKeyReference) {
        if let publicKeyRef = try? helper.getPublicKey(), let privateKey = try? helper.getPrivateKey() {
            return (public: publicKeyRef, private: privateKey)
        }
        else {
            let accessControl = try helper.accessControl(with: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
            let keypairResult = try helper.generateKeyPair(accessControl: accessControl)
            try helper.forceSavePublicKey(keypairResult.public)
            return (public: try helper.getPublicKey(), private: try helper.getPrivateKey())
        }
    }
}
