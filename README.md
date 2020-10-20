# public-key-pinning-ios
Sample implementation of public key pinning for iOS.

## Prerequisites
- MacOS with openssl
- XCode 12
- Swift 5

## Public key pinning
Note: no theory is explained here. This serves only as an example implementation for iOS.

### 1. Retrieve public key from a host. For this example we will use https://github.com (note that public key may change over time). Launch Terminal app and type:
```
openssl s_client -connect github:443 -showcerts < /dev/null | openssl x509 -outform der > server_cert.der
```
```
openssl x509 -inform der -in server_cert.der -pubkey -noout > server_cert_public_key.pem
```
```
cat server_cert_public_key.pem | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```

You'll get github's hashed public key (base64 encoded):
```
4PhpWPCTGkqmmjRFussirzvNSi4LjL7WWhUSAVFIXDc=
```
Store this key in some constant in your project.
See 'retrieve_public_key.sh' example.

### 2. Set delegate of NSURLSession and implement NSURLSessionDelegate's method:
```
func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
```

### 3. If challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust do the pinning:

Evaluate trust for the specified certificate:
```
if let serverTrust = challenge.protectionSpace.serverTrust {
    var secresult: CFError? = nil
    let certTrusted = SecTrustEvaluateWithError(serverTrust, &secresult)
```
If certificate is trusted, retrieve the certificate you want to do the pinning against. In the chain of trust, I will pick the leaf certificate, which is always at index 0:
```
let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
```
Get public key for this certificate:
```
let publicKey = SecCertificateCopyKey(serverCertificate)
```
Represent it as Data:
```
var error: Unmanaged<CFError>?
let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?
```
PublicKeyData is missing asn1 header. We need to add it, so we get the same hash:
```
let rsa2048Asn1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
      ]
var keyWithHeader = Data(rsa2048Asn1Header)
keyWithHeader.append(publicKeyData)
```
Now we have the same key, let's hash:
```
let digest = SHA256.hash(data: keyWithHeader)
```
And base64:
```
let digestString = Data(digest).base64EncodedString()
```
Now you can compare if digestString equals our stored hash from step 1.

## Example
See PublicKeyPinning sample project for reference.

## License

[public-key-pinning-ios](https://github.com/martinkrasnocka/public-key-pinning-ios) is protected under the [MIT license](http://www.opensource.org/licenses/mit-license.php)

Copyright 2020 Martin Krasnočka

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Donation

If you like this project, please consider donating [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=VUAUV9BSVNUYJ&currency_code=EUR&source=url)

