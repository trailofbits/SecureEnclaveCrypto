# Crypto with the Secure Enclave
Apple quietly released a new API in iOS 9 (`kSecAttrTokenIDSecureEnclave`) that allowed developers to create and use keys stored directly in the Secure Enclave (see "[Security and Your Apps](https://developer.apple.com/videos/play/wwdc2015/706/)" starting from slide 195). This feature opens enormous possibilities for security by enabling applications to use private keys that are safely stored outside of iOS and away from any potential malware.

We tried to use this API shortly after it was released and found it lacking: the required attribute was entirely undocumented, the key format is not compatible with OpenSSL, and Apple didn't even say what cipher suite was used (it's [secp256r1](https://www.ietf.org/rfc/rfc5480.txt)). The code in this repository is an attempt to fix these issues by providing an easy-to-use wrapper around the Secure Enclave Crypto API.

This project thus contains two codebases, one in [Swift](SecureEnclaveSwift) (from @hfossli) and one in [Objective-C](SecureEnclaveObjective-C) which show how to use this API for basic functionality. Both directories contain a README.md file with more specific documentation.
