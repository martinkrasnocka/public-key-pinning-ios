//
//  PublicKeyPinningHandler.swift
//  PublicKeyPinning
//
//  Created by Martin Krasnocka on 29/09/2020.
//

import Foundation
import CryptoKit

class PublicKeyPinningHandler {
    
    private static let serverPublicKeysHashes = ["4PhpWPCTGkqmmjRFussirzvNSi4LjL7WWhUSAVFIXDc="]
    private static let rsa2048Asn1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
      ]
    
    static func validateChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                var secresult: CFError? = nil
                let certTrusted = SecTrustEvaluateWithError(serverTrust, &secresult)
                let certCount = SecTrustGetCertificateCount(serverTrust)
                
                if (certTrusted && certCount > 0) {
                    if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) { // 0 is a leaf certificate
                        if let publicKey = SecCertificateCopyKey(serverCertificate) {
                            
                            var error: Unmanaged<CFError>?
                            if let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? {
                                var keyWithHeader = Data(rsa2048Asn1Header)
                                keyWithHeader.append(publicKeyData)
                                let digest = SHA256.hash(data: keyWithHeader)
                                let digestString = Data(digest).base64EncodedString()
                                
                                if serverPublicKeysHashes.contains(digestString) {
                                    // Pinning successfull
                                    print(String(format: "Pinning successfull: %@ %@", challenge.protectionSpace.host, digestString))
                                    completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: serverTrust))
                                    return
                                } else {
                                    print(String(format: "Pinning failed: %@ %@", challenge.protectionSpace.host, digestString))
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Pinning failed
        print(String(format: "Challenge failed: %@", challenge.protectionSpace.host))
        completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
    }
}
