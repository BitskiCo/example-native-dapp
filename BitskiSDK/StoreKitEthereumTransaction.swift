//
//  StoreKitEthereumTransaction.swift
//  BitskiSDK
//
//  Created by Patrick Tescher on 5/6/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Web3

public struct StoreKitEthereumTransaction: Codable {
    let transactionIdentifier: String
    let receiptData: Data
    let sandbox = false
    let ethereumTransaction: EthereumTransactionObject?
}
