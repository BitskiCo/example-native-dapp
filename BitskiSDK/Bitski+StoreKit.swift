//
//  Bitski+StoreKit.swift
//  BitskiSDK
//
//  Created by Patrick Tescher on 5/6/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import StoreKit
import PromiseKit
import Web3

extension Bitski {
    func process(transaction: SKPaymentTransaction) -> Promise<StoreKitEthereumTransaction> {
        return firstly {
            self.createRequest(transaction: transaction)
        }.then { request in
            self.send(request: request)
        }.then { data in
            return self.parseEthereumTransaction(data: data)
        }
    }

    func createRequest(transaction: SKPaymentTransaction) -> Promise<URLRequest> {
        guard let transactionIdentifier = transaction.transactionIdentifier, transaction.transactionState == .purchased else {
            let error = NSError(domain: "com.bitski", code: 500, userInfo: [NSLocalizedDescriptionKey: "The transaction did not complete"])
            return Promise(error: error)
        }

        let url = URL(string: "/v1/in-app-purchase-transaction", relativeTo: apiBaseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let accessToken = accessToken {
            request.setValue("Bearer: \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            let error = NSError(domain: "com.bitski", code: 500, userInfo: [NSLocalizedDescriptionKey: "No receipt"])
            return Promise(error: error)
        }

        do {
            let receiptData = try Data(contentsOf: receiptURL)

            let storekitEthereumTransaction = StoreKitEthereumTransaction(transactionIdentifier: transactionIdentifier, receiptData: receiptData, ethereumTransaction: nil)
            
            request.httpBody = try JSONEncoder().encode(storekitEthereumTransaction)

            return Promise.value(request)
        } catch {
            return Promise(error: error)
        }
    }

    func send(request: URLRequest) -> Promise<Data> {
        return Promise { resolver in
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    resolver.reject(error);
                } else if let data = data {
                    resolver.fulfill(data)
                } else {
                    assertionFailure()
                }
            }
        }
    }

    func parseEthereumTransaction(data: Data) -> Promise<StoreKitEthereumTransaction> {
        do {
            return Promise.value(try JSONDecoder().decode(StoreKitEthereumTransaction.self, from: data))
        } catch {
            return Promise(error: error)
        }
    }
}
