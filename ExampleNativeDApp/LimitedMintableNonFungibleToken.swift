//
//  TokenService.swift
//  ExampleNativeDApp
//
//  Created by Patrick Tescher on 5/5/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Web3
import PromiseKit

struct LimitedMintableNonFungibleToken {
    static let contractAddress = try! EthereumAddress(hex: "0x8c51dff8fcd48c292354ee751cceabeb25357df4", eip55: false)

    let web3: Web3

    let gas: EthereumQuantity? = nil
    let gasPrice: EthereumQuantity? = nil

    func getBalance(address: EthereumAddress) -> Promise<EthereumQuantity> {
        do {
            let call = try EthereumCall(from: nil, to: LimitedMintableNonFungibleToken.contractAddress, gas: nil, gasPrice: nil, function: "balanceOf(address)", parameters: [address.ethereumValue()])

            return firstly {
                self.web3.eth.call(call: call, block: .latest)
            }.then { balanceData -> Promise<EthereumQuantity> in
                let balance = balanceData.ethereumValue().ethereumQuantity!
                return Promise.value(balance)
            }
        } catch {
            return Promise(error: error)
        }
    }

    func getTokens(address: EthereumAddress) -> Promise<[EthereumValue]> {
        return firstly {
            self.getBalance(address: address)
        }.then{ balance -> Promise<[EthereumValue]> in
            let range = (0..<balance.quantity)

            let promises = range.map { index -> Promise<EthereumValue> in
                let indexValue = EthereumValue(integerLiteral: Int(index))
                return self.token(of: address, by: indexValue)
            }

            return when(fulfilled: promises)
        }
    }

    func token(of owner: EthereumAddress, by index: EthereumValue) -> Promise<EthereumValue> {
        do {
            let call = try EthereumCall(from: nil, to: LimitedMintableNonFungibleToken.contractAddress, gas: gas, gasPrice: gasPrice, function: "tokenOfOwnerByIndex(address,uint256)", parameters: [owner.ethereumValue(), index])
            return firstly {
                self.web3.eth.call(call: call, block: .latest)
            }.then { tokenData -> Promise<EthereumValue> in
                return Promise.value(tokenData.ethereumValue())
            }
        } catch {
            return Promise(error: error)
        }
    }
}
