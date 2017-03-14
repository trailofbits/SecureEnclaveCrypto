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
import Security

final class SecureEnclaveKeyReference {
    
    let underlying: SecKey
    
    fileprivate init(_ underlying: SecKey) {
        
        self.underlying = underlying
    }
}

final class SecureEnclaveKeyData {
    
    let underlying: [String: Any]
    let ref: SecureEnclaveKeyReference
    let data: Data
    
    fileprivate init(_ underlying: CFDictionary) {
        
        let converted = underlying as! [String: Any]
        self.underlying = converted
        self.data = converted[kSecValueData as String] as! Data
        self.ref = SecureEnclaveKeyReference(converted[kSecValueRef as String] as! SecKey)
    }
    
    var hex: String {
        
        return self.data.map { String(format: "%02hhx", $0) }.joined()
    }
}

struct SecureEnclaveHelperError: Error {
    
    let message: String
    let osStatus: OSStatus?
    let link: String
    
    init(message: String, osStatus: OSStatus?) {
        
        self.message = message
        self.osStatus = osStatus
        
        if let code = osStatus {
            
            link = "https://www.osstatus.com/search/results?platform=all&framework=Security&search=\(code)"
        }
        else {
            
            link = ""
        }
    }
}

final class SecureEnclaveHelper {
    
    let publicLabel: String
    let privateLabel: String
    let operationPrompt: String
    
    /*!
     *  @param publicLabel  The user visible label in the device's key chain
     *  @param privateLabel The label used to identify the key in the secure enclave
     */
    init(publicLabel: String, privateLabel: String, operationPrompt: String) {
        
        self.publicLabel = publicLabel
        self.privateLabel = privateLabel
        self.operationPrompt = operationPrompt
    }
    
    func sign(_ digest: Data, privateKey: SecureEnclaveKeyReference) throws -> Data {
        
        let blockSize = 256
        let maxChunkSize = blockSize - 11
        
        guard digest.count / MemoryLayout<UInt8>.size <= maxChunkSize else {
            
            throw SecureEnclaveHelperError(message: "data length exceeds \(maxChunkSize)", osStatus: nil)
        }
        
        var digestBytes = [UInt8](repeating: 0, count: digest.count / MemoryLayout<UInt8>.size)
        digest.copyBytes(to: &digestBytes, count: digest.count)
        
        var signatureBytes = [UInt8](repeating: 0, count: blockSize)
        var signatureLength = blockSize
        
        let status = SecKeyRawSign(privateKey.underlying, .PKCS1, digestBytes, digestBytes.count, &signatureBytes, &signatureLength)
        
        guard status == errSecSuccess else {
            
            if status == errSecParam {
                
                throw SecureEnclaveHelperError(message: "Could not create signature due to bad parameters", osStatus: status)
            }
            else {
                
                throw SecureEnclaveHelperError(message: "Could not create signature", osStatus: status)
            }
        }
        
        return Data(bytes: UnsafePointer<UInt8>(signatureBytes), count: signatureLength)
    }
    
    func getPublicKey() throws -> SecureEnclaveKeyData {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: attrKeyTypeEllipticCurve,
            kSecAttrApplicationTag as String: publicLabel,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecReturnData as String: true,
            kSecReturnRef as String: true,
            kSecReturnPersistentRef as String: true,
        ]
        
        let raw = try getSecKeyWithQuery(query)
        return SecureEnclaveKeyData(raw as! CFDictionary)
    }
    
    func getPrivateKey() throws -> SecureEnclaveKeyReference {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrLabel as String: privateLabel,
            kSecReturnRef as String: true,
            kSecUseOperationPrompt as String: self.operationPrompt,
        ]
        
        let raw = try getSecKeyWithQuery(query)
        return SecureEnclaveKeyReference(raw as! SecKey)
    }
    
    func generateKeyPair(accessControl: SecAccessControl) throws -> (`public`: SecureEnclaveKeyReference, `private`: SecureEnclaveKeyReference) {
        
        let privateKeyParams: [String: Any] = [
            kSecAttrLabel as String: privateLabel,
            kSecAttrIsPermanent as String: true,
            kSecAttrAccessControl as String: accessControl,
        ]
        let params: [String: Any] = [
            kSecAttrKeyType as String: attrKeyTypeEllipticCurve,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: privateKeyParams
        ]
        var publicKey, privateKey: SecKey?
        
        let status = SecKeyGeneratePair(params as CFDictionary, &publicKey, &privateKey)
        
        guard status == errSecSuccess else {
            
            throw SecureEnclaveHelperError(message: "Could not generate keypair", osStatus: status)
        }
        
        return (public: SecureEnclaveKeyReference(publicKey!), private: SecureEnclaveKeyReference(privateKey!))
    }
    
    func deletePublicKey() throws {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: attrKeyTypeEllipticCurve,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrApplicationTag as String: publicLabel
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            
            throw SecureEnclaveHelperError(message: "Could not delete private key", osStatus: status)
        }
    }
    
    func deletePrivateKey() throws {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrLabel as String: privateLabel,
            kSecReturnRef as String: true,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            
            throw SecureEnclaveHelperError(message: "Could not delete private key", osStatus: status)
        }
    }
    
    func verify(signature: Data, digest: Data, publicKey: SecureEnclaveKeyReference) throws -> Bool {
        
        var digestBytes = [UInt8](repeating: 0, count: digest.count)
        digest.copyBytes(to: &digestBytes, count: digest.count)
        
        var signatureBytes = [UInt8](repeating: 0, count: signature.count)
        signature.copyBytes(to: &signatureBytes, count: signature.count)
        
        let status = SecKeyRawVerify(publicKey.underlying, .PKCS1, digestBytes, digestBytes.count, signatureBytes, signatureBytes.count)
        
        guard status == errSecSuccess else {
            
            throw SecureEnclaveHelperError(message: "Could not create signature", osStatus: status)
        }
        
        return true
    }
    
    @available(iOS 10.3, *)
    func encrypt(_ digest: Data, publicKey: SecureEnclaveKeyReference) throws -> Data {
        
        var error : Unmanaged<CFError>?

        let result = SecKeyCreateEncryptedData(publicKey.underlying, SecKeyAlgorithm.eciesEncryptionStandardX963SHA256AESGCM, digest as CFData, &error)
        
        if result == nil {
            
            throw SecureEnclaveHelperError(message: "\(error)", osStatus: 0)
        }

        return result as! Data
    }
    
    @available(iOS 10.3, *)
    func decrypt(_ digest: Data, privateKey: SecureEnclaveKeyReference) throws -> Data {
        
        var error : Unmanaged<CFError>?
        
        let result = SecKeyCreateDecryptedData(privateKey.underlying, SecKeyAlgorithm.eciesEncryptionStandardX963SHA256AESGCM, digest as CFData, &error)
        
        if result == nil {
            
            throw SecureEnclaveHelperError(message: "\(error)", osStatus: 0)
        }
        
        return result as! Data
    }
    
    func forceSavePublicKey(_ publicKey: SecureEnclaveKeyReference) throws {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: attrKeyTypeEllipticCurve,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrApplicationTag as String: publicLabel,
            kSecValueRef as String: publicKey.underlying,
            kSecAttrIsPermanent as String: true,
            kSecReturnData as String: true,
        ]
        
        var raw: CFTypeRef?
        var status = SecItemAdd(query as CFDictionary, &raw)
        
        if status == errSecDuplicateItem {
            
            status = SecItemDelete(query as CFDictionary)
            status = SecItemAdd(query as CFDictionary, &raw)
        }
        
        guard status == errSecSuccess else {
            
            throw SecureEnclaveHelperError(message: "Could not save keypair", osStatus: status)
        }
    }
    
    func accessControl(with protection: CFString = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, flags: SecAccessControlCreateFlags = [.userPresence, .privateKeyUsage]) throws -> SecAccessControl {
        
        var accessControlError: Unmanaged<CFError>?
        
        let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, protection, flags, &accessControlError)
        
        guard accessControl != nil else {
            
            throw SecureEnclaveHelperError(message: "Could not generate access control. Error \(accessControlError?.takeRetainedValue())", osStatus: nil)
        }
        
        return accessControl!
    }
    
    private var attrKeyTypeEllipticCurve: String {
        
        if #available(iOS 10.0, *) {
            
            return kSecAttrKeyTypeECSECPrimeRandom as String
        }
        else {
            
            return kSecAttrKeyTypeEC as String
        }
    }
    
    private func getSecKeyWithQuery(_ query: [String: Any]) throws -> CFTypeRef {
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            
            throw SecureEnclaveHelperError(message: "Could not get key for query: \(query)", osStatus: status)
        }
        
        return result!
    }
}
