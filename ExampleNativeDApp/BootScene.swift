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

class BootScene: SKScene {
    static let noAccountError = NSError(domain: "com.bitski", code: 505, userInfo: [NSLocalizedDescriptionKey: "No Accounts"])

    var web3: Web3? {
        didSet {
            guard let web3 = web3 else { return assertionFailure() }

            let tokenContract = LimitedMintableNonFungibleToken(web3: web3)

            firstly {
                web3.eth.accounts()
            }.then { addresses -> Promise<[EthereumValue]> in
                guard let address = addresses.first else {
                    return Promise(error: BootScene.noAccountError)
                }
                return tokenContract.getTokens(address: address)
            }.done { tokens in
                guard let crewScene = CrewScene(fileNamed: "CrewScene") else {
                    return assertionFailure()
                }
                
                crewScene.tokens = tokens
                crewScene.web3 = web3

                self.view?.presentScene(crewScene)
            }.catch { error in
                Swift.print("Got an error: \(error)")
            }
        }
    }
}
