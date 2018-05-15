//
//  CrewScene.swift
//  ExampleNativeDApp
//
//  Created by Patrick Tescher on 5/6/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import SpriteKit
import BitskiSDK
import PromiseKit
import Web3
import BigInt

class TouchableNode: SKSpriteNode {
    var onTouchUp: (() -> Void)?
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        onTouchUp?()
    }
}

class CrewScene: SKScene {
    
    private (set) var tokens = [BigUInt]()
    private var web3: Web3?
    var tokenContract: LimitedMintableNonFungibleToken?
    var currentAccount: EthereumAddress?
    
    var getMoreNode: SKNode!
    
    private var sprites: [SKSpriteNode] = []
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    public func set(tokens: [BigUInt], web3: Web3, currentAccount: EthereumAddress, contract: LimitedMintableNonFungibleToken) {
        self.tokens = tokens
        self.web3 = web3
        self.tokenContract = contract
        self.currentAccount = currentAccount
        if tokens.count >= 5 {
            getMoreNode.isHidden = true
        }
        if let node = childNode(withName: "Title") as? SKLabelNode {
            if tokens.count == 0 {
                node.text = "You don't have any guys yet!"
            } else if tokens.count == 1 {
                node.text = "You have one guy"
            } else if tokens.count == 5 {
                node.text = "You have a complete crew! Yay!"
            } else {
                node.text = "You have \(tokens.count) guys"
            }
        }
    }
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        getMoreNode = childNode(withName: "GetMore")
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        let sprites = tokens.map { createGuy(token: $0) }
        
        for (n, sprite) in sprites.enumerated() {
            addGuy(sprite: sprite, index: n)
        }
    }
    
    func addGuy(sprite: SKSpriteNode, index: Int) {
        let startX: CGFloat = -100
        let offsetAmount: CGFloat = 50
        let y = CGFloat((index % 2) > 0 ? 100 : 150)
        let x: CGFloat = startX + (CGFloat(index) * offsetAmount)
        sprite.position = CGPoint(x: x, y: y)
        
        addChild(sprite)
    }
    
    func createGuy(token: BigUInt) -> SKSpriteNode {
        let imageIndex = (token % BigUInt(5)) + 1
        let imageName = "character-\(imageIndex)"
        let sprite = TouchableNode(imageNamed: imageName)
        sprite.isUserInteractionEnabled = true
        sprite.onTouchUp = { [weak self] in
            self?.showDetails(token: token)
        }
        return sprite
    }
    
    func getMore() {
        guard let contract = tokenContract, let currentAccount = currentAccount else {
            return assertionFailure()
        }
        firstly {
            contract.mintNewToken(address: currentAccount)
        }.done { hash in
            self.showTransaction(transactionHash: hash)
        }.catch { error in
            print("Error getting more", error)
        }
    }
    
    func showTransaction(transactionHash: EthereumData) {
        guard let transactionScene = TransactionScene(fileNamed: "TransactionScene"), let web3 = web3, let contract = tokenContract else {
            return assertionFailure()
        }
        transactionScene.set(web3: web3, contract: contract, transactionHash: transactionHash)
        self.view?.presentScene(transactionScene)
    }
    
    func showDetails(token: BigUInt) {
        //transition to unit scene
        guard let unitScene = UnitScene(fileNamed: "UnitScene"), let web3 = web3, let currentAccount = currentAccount, let contract = tokenContract else {
            return assertionFailure()
        }
        
        unitScene.set(token: token, web3: web3, currentAccount: currentAccount, contract: contract)
        self.view?.presentScene(unitScene)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        for touch in (touches) {
            
            let location = touch.location(in: self)
            if atPoint(location) == self.getMoreNode {
                getMore()
            }
        }
    }
}
