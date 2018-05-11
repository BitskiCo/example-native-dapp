//
//  EthereumCallFunction.swift
//  BitskiSDK
//
//  Created by Patrick Tescher on 5/5/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Web3

public extension EthereumCall {

    public init(from: EthereumAddress? = nil, to: EthereumAddress, gas: EthereumQuantity? = nil, gasPrice: EthereumQuantity? = nil, function: String, parameters: [EthereumValue]) throws {

        var functionWithParameters = parameters;
        let functionString = String(function.sha3(.keccak256).prefix(8))
        functionWithParameters.insert(EthereumValue(stringLiteral: functionString), at: 0)

        let value = EthereumValue(array: functionWithParameters)


        let ethereumData = try EthereumData(ethereumValue: value)

        self.init(from: from, to: to, gas: gas, gasPrice: gasPrice, value: nil, data: ethereumData)
    }
}
