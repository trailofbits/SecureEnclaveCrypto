# Crypto with the Secure Enclave
Apple quietly released a new API in iOS 9 (`kSecAttrTokenIDSecureEnclave`) that allowed developers to create and use keys stored directly in the Secure Enclave (see "[Security and Your Apps](https://developer.apple.com/videos/play/wwdc2015/706/)" starting from slide 195). This feature opens enormous possibilities for security by enabling applications to use private keys that are safely stored outside of iOS and away from any potential malware. We tried to use this API shortly after it was released and found it lacking: the required attribute was entirely undocumented, the key format is not compatible with OpenSSL, and Apple didn't even say what cipher suite was used (it's [secp256r1](https://www.ietf.org/rfc/rfc5480.txt)). The code in this repository is an attempt to fix these issues by providing an easy-to-use wrapper around the Secure Enclave.

## KeyInterface
This iOS library wraps calls to the Secure Enclave for key management and data signing.

## Example Project
The example iOS project demonstrates how to use KeyInterface on a blank view to print a public key and sign data. The key names are constantized as `kPublicKeyName` and `kPrivateKeyName` in `KeyInterface.h`. You should change those values to match identifiers for your company and project.

```
2016-06-22 15:28:30.551 sep-example[3878:1760576] Public key raw bits:
<045ac9bd 7c4d8e77 b37fd14f bf2822ac 4ad4d62f 1bce4019 60bdbdc7 1102da0c 78603266 7dd0fe8b 2a847135 1d1d0e01 a2cd019e ab9c4b7c 9a3fed15 1f20bcc2 9a>  

2016-06-22 15:28:34.530 sep-example[3878:1760576] Signature for data:
<30460221 008f3739 b01f6fad 3260e2f4 7de0e9ad 6f716230 a0bf6479 9885e78f 98dcfd86 4c022100 c5dafb94 7b7ae5ea 407fd922 dc2ac253 cc3120d6 8c8f73a0 3e69c8d3 97231da8>
```

## key_builder.rb
Data returned by the Secure Enclave can be fed to `key_builder.rb` to create an OpenSSL-compatible representation of the ECC public key.

```bash
$ ruby key_builder.rb "045ac9bd 7c4d8e77 b37fd14f bf2822ac 4ad4d62f 1bce4019 60bdbdc7 1102da0c 78603266 7dd0fe8b 2a847135 1d1d0e01 a2cd019e ab9c4b7c 9a3fed15 1f20bcc2 9a"

-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEsng2kkyuVVqyK1BRo8EZhJTM
Mubz1P4MvF6TVwmnbCEUGv4IssA8FXqNb2txbLtlYvNiJPjss/62HKMvR2tm
uA==
-----END PUBLIC KEY-----
```
