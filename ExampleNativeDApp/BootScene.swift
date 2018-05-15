//
//  BootScene.swift
//  ExampleNativeDApp
//
//  Created by Patrick Tescher on 5/5/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import SpriteKit
import Web3
import PromiseKit
import BigInt

class BootScene: SKScene {
    static let noAccountError = NSError(domain: "com.bitski", code: 505, userInfo: [NSLocalizedDescriptionKey: "No Accounts"])
    private var contract: LimitedMintableNonFungibleToken?
    private var web3: Web3?
    private var currentAccount: EthereumAddress?
    
    func set(web3: Web3, contract: LimitedMintableNonFungibleToken) {
        self.web3 = web3
        self.contract = contract
        getTokens()
    }
    
    func getTokens() {
        guard let web3 = web3, let tokenContract = contract else { return assertionFailure() }
        
        firstly {
            web3.eth.accounts()
        }.then { addresses -> Promise<[BigUInt]> in
            guard let address = addresses.first else {
                return Promise(error: BootScene.noAccountError)
            }
            self.currentAccount = address
            return tokenContract.getOwnerTokens(address: address)
        }.done { tokens in
            if tokens.count > 0 {
                self.showCrewScene(tokens: tokens)
            } else {
                _ = web3.eth.getBalance(address: self.currentAccount!, block: .latest).done { balance in
                    if balance.quantity > 0 {
                        self.showCrewScene(tokens: [])
                    } else {
                        self.showNeedFundsScene()
                    }
                }
            }
        }.catch { error in
            print("Got an error: \(error)")
        }
    }
    
    func showCrewScene(tokens: [BigUInt]) {
        guard let crewScene = CrewScene(fileNamed: "CrewScene"), let web3 = web3, let currentAccount = currentAccount, let tokenContract = contract else {
            return assertionFailure()
        }
        
        crewScene.set(tokens: tokens, web3: web3, currentAccount: currentAccount, contract: tokenContract)
        
        self.view?.presentScene(crewScene)
    }
    
    func showNeedFundsScene() {
        guard let scene = NeedFundsScene(fileNamed: "NeedFundsScene"), let web3 = web3, let currentAccount = currentAccount, let tokenContract = contract else {
            return assertionFailure()
        }
        
        scene.set(web3: web3, currentAddress: currentAccount, contract: tokenContract)
        
        self.view?.presentScene(scene)
    }
}
