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

public let CurrentNetwork: Bitski.Network? = .rinkeby
public let DevelopmentHost: String = "http://localhost:9545"

class LimitedMintableNonFungibleToken: GenericERC721Contract, EnumeratedERC721 {
    
    static let contractAddress = try! EthereumAddress(hex: "0xe11ccb2cc5a17aac6d1484788562efcd21a7f859", eip55: false)
    
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
        super.init(address: LimitedMintableNonFungibleToken.contractAddress, eth: web3.eth)
    }
    
    required init(address: EthereumAddress?, eth: Web3.Eth) {
        super.init(address: address, eth: eth)
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
    
    func mintNewToken(from: EthereumAddress) -> Promise<(BigUInt, EthereumData)> {
        do {
            let tokenHex = try randomHex(bytesCount: 32)
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
