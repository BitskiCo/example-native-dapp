//
//  UnitScene.swift
//  ExampleNativeDApp
//
//  Created by Josh Pyles on 5/14/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Foundation
import SpriteKit
import BigInt
import Web3
import Bitski
import PromiseKit

class UnitScene: SKScene {
    
    private (set) var token: BigUInt?
    private (set) var contract: LimitedMintableNonFungibleToken?
    private (set) var currentAccount: EthereumAddress?
    private (set) var web3: Web3?
    
    private var deleteNode: SKTouchSprite?
    private var backNode: SKTouchSprite?
    private var tokenNode: SKSpriteNode?
    
    func set(token: BigUInt, web3: Web3, currentAccount: EthereumAddress, contract: LimitedMintableNonFungibleToken) {
        self.token = token
        self.web3 = web3
        self.contract = contract
        self.currentAccount = currentAccount
        drawToken()
    }
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        deleteNode = childNode(withName: "DeleteButton") as? SKTouchSprite
        deleteNode?.pressedTexture = SKTexture(imageNamed: "deleteBtnPressed")
        deleteNode?.touchHandler = { _ in
            self.delete()
        }
        backNode = childNode(withName: "BackButton") as? SKTouchSprite
        backNode?.pressedTexture = SKTexture(imageNamed: "backBtnPressed")
        backNode?.touchHandler = { _ in
            self.back()
        }
    }
    
    func drawToken() {
        guard let token = token else { return }
        if let existingNode = self.tokenNode {
            existingNode.removeFromParent()
        }
        let index = (token % 5) + 1
        let spriteNode = SKSpriteNode(imageNamed: "character-\(index)")
        spriteNode.position = CGPoint(x: 0, y: 0)
        addChild(spriteNode)
        self.tokenNode = spriteNode
    }
    
    func delete() {
        guard let contract = contract, let currentAccount = currentAccount, let token = token else {
            return assertionFailure()
        }
        firstly {
            contract.deleteToken(from: currentAccount, tokenID: token)
        }.done { hash in
            self.showTransaction(transactionHash: hash)
        }.catch { error in
            print(error)
        }
    }
    
    func back() {
        guard let scene = BootScene(fileNamed: "BootScene"), let web3 = web3, let contract = contract else {
            return assertionFailure()
        }
        scene.set(web3: web3, contract: contract)
        self.view?.presentScene(scene)
    }
    
    func showTransaction(transactionHash: EthereumData) {
        guard let transactionScene = TransactionScene(fileNamed: "TransactionScene"), let web3 = web3, let contract = contract else {
            return assertionFailure()
        }
        transactionScene.set(web3: web3, contract: contract, transactionHash: transactionHash)
        self.view?.presentScene(transactionScene)
    }
}
