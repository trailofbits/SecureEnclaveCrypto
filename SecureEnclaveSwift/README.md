Secure Enclave Swift
====================

This project shows you how to 
- create a keypair where as the private key is stored in the secure enclave
- sign a string / some data with the private key
- use the security functions like SecKeyRawVerify, SecKeyGeneratePair and SecItemCopyMatching in Swift 3
- store the public key in the keychain

The keypair uses Elliptic curve algorithm (secp256r1) with PKCS1 padding.

It was a bit tricky to find out how to do all this in Swift 3, so here it is :)

Inspired by [https://github.com/trailofbits/SecureEnclaveCrypto](https://github.com/trailofbits/SecureEnclaveCrypto).

