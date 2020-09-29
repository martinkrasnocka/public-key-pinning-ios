//
//  ViewModel.swift
//  PublicKeyPinning
//
//  Created by Martin Krasnocka on 29/09/2020.
//

import Foundation

class ViewModel: ObservableObject {
    
    internal let session: URLSession
    @Published var result = ""
    
    init() {
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: PinningDelegate(), delegateQueue: OperationQueue.main)
        result = "GET https://github.com"
        
        var urlRequest = URLRequest(url: URL(string: "https://github.com")!)
        urlRequest.httpMethod = "GET"
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                self.result = self.result + "\n" + error.localizedDescription
            } else {
                self.result = self.result + "\n" + "Pinning succeeded!"
            }
        }
        task.resume()
    }
}

class PinningDelegate: NSObject, URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        PublicKeyPinningHandler.validateChallenge(challenge, completionHandler: completionHandler)
    }
}
