//
//  AuthScene.swift
//  ExampleNativeDApp
//
//  Created by Patrick Tescher on 5/5/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import SpriteKit
import Web3
import Bitski

class AuthScene: SKScene {
    var loginButtonNode: SKTouchSprite?

    override func sceneDidLoad() {
        super.sceneDidLoad()

        loginButtonNode = childNode(withName: "LoginButton") as? SKTouchSprite
        loginButtonNode?.pressedTexture = SKTexture(imageNamed: "startBtnPressed")
        loginButtonNode?.isUserInteractionEnabled = true
        loginButtonNode?.touchHandler = { _ in
            self.signIn()
        }
        
        let scaleDownAction = SKAction.scale(to: 0.95, duration: 1.0)
        let scaleUpAction = SKAction.scale(to: 1.0, duration: 1.0)
        let sequenceAction = SKAction.sequence([scaleDownAction, scaleUpAction])
        let loopAction = SKAction.repeatForever(sequenceAction)
        loginButtonNode?.run(loopAction)
    }
    
    func signIn() {
        guard let bitski = Bitski.shared else {
            return assertionFailure()
        }
        bitski.signIn() { (_, error) in
            if error == nil {
                self.showBootScene(web3: bitski.getWeb3(network: .kovan))
            } else {
                print(error)
            }
        }
    }
    
    func showBootScene(web3: Web3) {
        let contract = LimitedMintableNonFungibleToken(web3: web3)
        
        if let scene = BootScene(fileNamed: "BootScene") {
            scene.set(web3: web3, contract: contract)
            let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.5)
            view?.presentScene(scene, transition: transition)
        }
    }
}
