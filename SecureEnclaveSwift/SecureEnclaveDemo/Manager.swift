//
//  Manager.swift
//  BankAxept
//
//  Created by Håvard Fossli on 11.11.2016.
//  Copyright © 2016 BankAxept. All rights reserved.
//

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
