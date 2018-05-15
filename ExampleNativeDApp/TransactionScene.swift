//
//  TransactionScene.swift
//  ExampleNativeDApp
//
//  Created by Josh Pyles on 5/14/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Foundation
import SpriteKit
import BitskiSDK
import PromiseKit
import Web3

class TransactionScene: SKScene {
    
    var web3: Web3?
    var contract: LimitedMintableNonFungibleToken?
    var transactionHash: EthereumData?
    var transactionWatcher: TransactionWatcher?
    
    var labelNode: SKLabelNode?
    
    func set(web3: Web3, contract: LimitedMintableNonFungibleToken, transactionHash: EthereumData) {
        self.web3 = web3
        self.contract = contract
        self.transactionHash = transactionHash
        NotificationCenter.default.addObserver(forName: TransactionWatcher.StatusDidChangeNotification, object: nil, queue: nil) { [weak self] notification in
            if let status = self?.transactionWatcher?.status {
                self?.configureScene(status: status)
            }
        }
        transactionWatcher = TransactionWatcher(transactionHash: transactionHash, web3: web3)
        configureScene(status: transactionWatcher!.status)
    }
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        labelNode = childNode(withName: "Label") as? SKLabelNode
    }
    
    func configureScene(status: TransactionWatcher.Status) {
        switch status {
        case .pending:
            labelNode?.text = "Waiting for confirmation"
        case .approved(let times):
            labelNode?.text = "Received confirmation \(times) / \(transactionWatcher?.expectedConfirmations ?? 6)"
        case .failed:
            labelNode?.text = "Transaction failed"
        case .successful:
            labelNode?.text = "Success!"
            after(seconds: 1.0).done { _ in
                self.showBootScreen()
            }
        }
    }
    
    func showBootScreen() {
        guard let bootScene = BootScene(fileNamed: "BootScene"), let web3 = web3, let contract = contract else {
            return assertionFailure()
        }
        bootScene.set(web3: web3, contract: contract)
        self.view?.presentScene(bootScene)
    }
    
}
