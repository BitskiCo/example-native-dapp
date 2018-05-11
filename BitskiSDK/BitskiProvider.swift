//
//  BitskiProvider.swift
//  BitskiSDK
//
//  Created by Patrick Tescher on 5/5/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Web3
import SafariServices

public class BitskiHTTPProvider: Web3Provider {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let queue: DispatchQueue

    let session: URLSession

    let callbackURLScheme: String?
    let networkName: String

    public var headers = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]

    public let rpcURL: URL

    public init(rpcURL: URL, networkName: String, session: URLSession = URLSession(configuration: .default), callbackURLScheme: String? = nil) {
        self.rpcURL = rpcURL
        self.networkName = networkName
        self.session = session
        self.callbackURLScheme = callbackURLScheme
        self.queue = DispatchQueue(label: "BitskiHttpProvider", attributes: .concurrent)
    }

    private func requiresAuthorization<Params>(request: RPCRequest<Params>) -> Bool {
        switch request.method {
        case "eth_sendTransaction":
            return true
        default:
            return false
        }
    }

    public func send<Params, Result>(request: RPCRequest<Params>, response: @escaping Web3ResponseCompletion<Result>) {
        queue.async {
            guard let body = try? self.encoder.encode(request) else {
                let err = Web3Response<Result>(status: .requestFailed)
                response(err)
                return
            }

            if self.requiresAuthorization(request: request) {
                self.sendViaWeb(encodedPayload: body, response: response)
                return
            }

            var req = URLRequest(url: self.rpcURL)
            req.httpMethod = "POST"
            req.httpBody = body
            for (k, v) in self.headers {
                req.addValue(v, forHTTPHeaderField: k)
            }

            let task = self.session.dataTask(with: req) { data, urlResponse, error in
                guard let urlResponse = urlResponse as? HTTPURLResponse, let data = data, error == nil else {
                    let err = Web3Response<Result>(status: .serverError)
                    response(err)
                    return
                }

                let status = urlResponse.statusCode
                guard status >= 200 && status < 300 else {
                    // This is a non typical rpc error response and should be considered a server error.
                    let err = Web3Response<Result>(status: .serverError)
                    response(err)
                    return
                }

                guard let rpcResponse = try? self.decoder.decode(RPCResponse<Result>.self, from: data) else {
                    // We don't have the response we expected...
                    let err = Web3Response<Result>(status: .serverError)
                    response(err)
                    return
                }

                // We got the Result object
                let res = Web3Response(status: .ok, rpcResponse: rpcResponse)
                response(res)
            }
            task.resume()
        }
    }

    public func sendViaWeb<Result>(encodedPayload: Data, response: @escaping Web3ResponseCompletion<Result>) {
        let accessToken = ""
        let ethSendTransactionUrl = URL(string: "https://www.bitski.com/eth-send-transaction?network=\(networkName)&payload=\(encodedPayload)&accessToken=\(accessToken)")

        let session = SFAuthenticationSession(url: ethSendTransactionUrl!, callbackURLScheme: callbackURLScheme) { (url, error) in
            if error != nil {
                let err = Web3Response<Result>(status: .serverError)
                response(err)
            }

            if let url = url {
                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)

                guard let data = urlComponents?.queryItems?.filter( { (item) -> Bool in
                    item.name == "response"
                }).compactMap({ (queryItem) -> Data? in
                    return queryItem.value.flatMap { Data(base64Encoded: $0) }
                }).first else {
                    let err = Web3Response<Result>(status: .serverError)
                    response(err)
                    return
                }

                do {
                    let rpcResponse = try self.decoder.decode(RPCResponse<Result>.self, from: data)

                    let res = Web3Response(status: .ok, rpcResponse: rpcResponse)
                    response(res)
                } catch {
                    let err = Web3Response<Result>(status: .serverError)
                    response(err)
                }
            }
        }

        session.start()
    }
}
