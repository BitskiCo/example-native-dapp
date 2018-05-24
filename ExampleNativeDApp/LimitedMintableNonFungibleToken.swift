//
//  TokenService.swift
//  ExampleNativeDApp
//
//  Created by Patrick Tescher on 5/5/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Web3
import PromiseKit
import BigInt
import Bitski

enum ContractError: Error {
    case unknownBalance
}

class LimitedMintableNonFungibleToken: EthereumContract {
    static let contractAddress = try! EthereumAddress(hex: "0x8c51dff8fcd48c292354ee751cceabeb25357df4", eip55: false)
    let web3: Web3
    
    init(web3: Web3) {
        self.web3 = web3
    }
    
    //MARK: - Calls

    func getBalance(address: EthereumAddress) -> Promise<EthereumQuantity> {
        return firstly {
            self.call(functionName: "getBalance(address)", parameters: [address])
        }.then { balanceData -> Promise<EthereumQuantity> in
            if let balance = balanceData.ethereumValue().ethereumQuantity {
                return Promise.value(balance)
            }
            return Promise(error: ContractError.unknownBalance)
        }
    }
    
    func getOwnerTokens(address: EthereumAddress) -> Promise<[BigUInt]> {
        return firstly {
            self.call(functionName: "getOwnerTokens(address)", parameters: [address])
        }.then { callData -> Promise<[BigUInt]> in
            print(callData, callData.hex())
            return Parser.decodeArray(hexString: callData.hex())
        }
    }
    
    func getTokens(address: EthereumAddress) -> Promise<[EthereumValue]> {
        return firstly {
            self.getBalance(address: address)
        }.then { balance -> Promise<[EthereumValue]> in
            let range = (0..<balance.quantity)
            let promises = range.map { index -> Promise<EthereumValue> in
                let indexValue = EthereumValue(integerLiteral: Int(index))
                return self.token(of: address, by: indexValue)
            }
            return when(fulfilled: promises)
        }
    }
    
    func token(of owner: EthereumAddress, by index: EthereumValue) -> Promise<EthereumValue> {
        return firstly {
            self.call(functionName: "tokenOfOwnerByIndex(address,uint256)", parameters: [owner, index])
        }.then { tokenData -> Promise<EthereumValue> in
            return Promise.value(tokenData.ethereumValue())
        }
    }
    
    //MARK: - Sends
    
    func mintNewToken(address: EthereumAddress) -> Promise<(BigUInt, EthereumData)> {
        let functionName = "mint(uint256)"
        do {
            let tokenID = try Web3.utils.randomHex(bytesCount: 256)
            let parameters = ["0x\(tokenID)"]
            return self.send(functionName: functionName, parameters: parameters, fromAddress: address).map { hash in
                return (BigUInt(tokenID, radix: 16)!, hash)
            }
        } catch {
            return Promise(error: error)
        }
    }
    
    func deleteToken(from: EthereumAddress, tokenID: BigUInt) -> Promise<EthereumData> {
        let functionName = "transfer(address,uint256)"
        let parameters: [EthereumValueConvertible] = [LimitedMintableNonFungibleToken.contractAddress, tokenID]
        return self.send(functionName: functionName, parameters: parameters, fromAddress: from)
    }
    
}
