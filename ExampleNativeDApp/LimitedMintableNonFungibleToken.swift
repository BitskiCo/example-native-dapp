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
    
    static let contractAddress = try! EthereumAddress(hex: "0x8F83aADB8098a1B4509aaba77ba9d2cb1aC970BA", eip55: false)
    
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
    
    func mintWithTokenURI(to: EthereumAddress, tokenId: BigUInt, tokenURI: String) -> SolidityInvocation {
        let inputs = [
            SolidityFunctionParameter(name: "_to", type: .address),
            SolidityFunctionParameter(name: "_tokenId", type: .uint256),
            SolidityFunctionParameter(name: "_tokenURI", type: .string)
        ]
        let function = SolidityNonPayableFunction(name: "mintWithTokenURI", inputs: inputs, handler: self)
        return function.invoke(to, tokenId, tokenURI)
    }
    
    func burn(tokenId: BigUInt) -> SolidityInvocation {
        let inputs = [
            SolidityFunctionParameter(name: "tokenId", type: .uint256)
        ]
        let function = SolidityNonPayableFunction(name: "burn", inputs: inputs, handler: self)
        return function.invoke(tokenId)
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
            return self.getBalance(address: address)
        }.then { balance -> Promise<[BigUInt]> in
            let balanceInt = Int(balance.quantity)
            let promises = (0..<balanceInt).map {
                return self.getTokenId(address: address, index: $0)
            }
            return when(fulfilled: promises)
        }
    }
    
    func getTokenId(address: EthereumAddress, index: Int) -> Promise<BigUInt> {
        return firstly {
            return self.tokenOfOwnerByIndex(owner: address, index: BigUInt(index)).call()
        }.then { values -> Promise<BigUInt> in
            if let tokenId = values["_tokenId"] as? BigUInt {
                return Promise.value(tokenId)
            }
            return Promise(error: ContractError.unknownBalance)
        }
    }
    
    func mintNewToken(from: EthereumAddress) -> Promise<(BigUInt, EthereumData)> {
        do {
            let tokenHex = try randomHex(bytesCount: 32)
            let tokenID = BigUInt(hexString: tokenHex)!
            let tokenURI = "https://example-dapp-1-api.bitski.com/tokens/\(tokenID)"
            return mintWithTokenURI(to: from, tokenId: tokenID, tokenURI: tokenURI).send(from: from, value: nil, gas: 1000000, gasPrice: nil).map { hash in
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
        return burn(tokenId: tokenID).send(from: from, value: nil, gas: 700000, gasPrice: nil)
    }
    
}
