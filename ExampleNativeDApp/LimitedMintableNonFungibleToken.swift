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
    case contractNotDeployed
    case unknownBalance
}

class LimitedMintableNonFungibleToken: GenericERC721Contract {
    
    static let contractAddress = try! EthereumAddress(hex: "0x8c51dff8fcd48c292354ee751cceabeb25357df4", eip55: false)
    
    static let Mint = SolidityEvent(name: "Mint", anonymous: false, inputs: [
        SolidityEvent.Parameter(name: "_to", type: .address, indexed: true),
        SolidityEvent.Parameter(name: "_tokenId", type: .uint, indexed: true),
    ])
    
    override var events: [SolidityEvent] {
        return [
            LimitedMintableNonFungibleToken.Transfer,
            LimitedMintableNonFungibleToken.Approval,
            LimitedMintableNonFungibleToken.Mint
        ]
    }
    
    init(web3: Web3) {
        super.init(name: "LimitedMintableNonFungibleToken", address: LimitedMintableNonFungibleToken.contractAddress, eth: web3.eth)
    }
    
    required init(name: String, address: EthereumAddress?, eth: Web3.Eth) {
        super.init(name: name, address: address, eth: eth)
    }
    
    //MARK: - Methods
    
    func mint(tokenId: BigUInt) -> SolidityInvocation {
        let inputs = [SolidityFunctionParameter(name: "_tokenId", type: .uint256)]
        let function = SolidityNonPayableFunction(name: "mint", inputs: inputs, handler: self)
        return function.invoke(tokenId)
    }
    
    func getOwnerTokens(owner: EthereumAddress) -> SolidityInvocation {
        let inputs = [SolidityFunctionParameter(name: "_owner", type: .address)]
        let outputs = [SolidityFunctionParameter(name: "_tokenIds", type: .array(type: .uint256, length: nil))]
        let function = SolidityConstantFunction(name: "getOwnerTokens", inputs: inputs, outputs: outputs, handler: self)
        return function.invoke(owner)
    }
    
    func token(of owner: EthereumAddress, by index: BigUInt) -> SolidityInvocation {
        let inputs = [
            SolidityFunctionParameter(name: "_owner", type: .address),
            SolidityFunctionParameter(name: "_index", type: .uint)
        ]
        let outputs = [SolidityFunctionParameter(name: "_tokenId", type: .uint)]
        let function = SolidityConstantFunction(name: "tokenOfOwnerByIndex", inputs: inputs, outputs: outputs, handler: self)
        return function.invoke(owner, index)
    }
    
    //MARK: - Convenience
    
    func getBalance(address: EthereumAddress) -> Promise<EthereumQuantity> {
        return firstly {
            return self.balanceOf(address: address).call()
        }.then { values -> Promise<EthereumQuantity> in
            if let balance = values["_balance"] as? BigUInt {
                return Promise.value(EthereumQuantity(quantity: balance))
            }
            return Promise(error: ContractError.unknownBalance)
        }
    }
    
    func getOwnerTokens(address: EthereumAddress) -> Promise<[BigUInt]> {
        return firstly {
            return self.getOwnerTokens(owner: address).call()
        }.then { values -> Promise<[BigUInt]> in
            if let tokens = values["_tokenIds"] as? [BigUInt] {
                return Promise.value(tokens)
            }
            return Promise(error: ContractError.unknownBalance)
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
            token(of: owner, by: try! BigUInt(ethereumValue: index)).call()
        }.then { values -> Promise<EthereumValue> in
            if let tokenId = values["_tokenId"] as? BigUInt {
                return Promise.value(tokenId.ethereumValue())
            }
            return Promise(error: ContractError.unknownBalance)
        }
    }
    
    func mintNewToken(from: EthereumAddress) -> Promise<(BigUInt, EthereumData)> {
        do {
            let tokenHex = try Web3.utils.randomHex(bytesCount: 32)
            let tokenID = BigUInt(hexString: tokenHex)!
            return mint(tokenId: tokenID).send(from: from, value: nil, gas: 700000, gasPrice: nil).map { hash in
                return (tokenID, hash)
            }
        } catch {
            return Promise(error: error)
        }
    }
    
    func deleteToken(from: EthereumAddress, tokenID: BigUInt) -> Promise<EthereumData> {
        guard let to = address else {
            return Promise(error: ContractError.contractNotDeployed)
        }
        return transfer(to: to, tokenId: tokenID).send(from: from, value: nil, gas: 700000, gasPrice: nil)
    }
    
}
