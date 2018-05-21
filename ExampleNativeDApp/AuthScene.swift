//
//  AuthScene.swift
//  ExampleNativeDApp
//
//  Created by Patrick Tescher on 5/5/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import SpriteKit
import Bitski

class AuthScene: SKScene {
    var loginButtonNode: SKTouchSprite?

    var signIn: (()->Void)?

    override func sceneDidLoad() {
        super.sceneDidLoad()

        loginButtonNode = childNode(withName: "LoginButton") as? SKTouchSprite
        loginButtonNode?.pressedTexture = SKTexture(imageNamed: "startBtnPressed")
        loginButtonNode?.isUserInteractionEnabled = true
        loginButtonNode?.touchHandler = { _ in
            self.signIn?()
        }
        
        let scaleDownAction = SKAction.scale(to: 0.95, duration: 1.0)
        let scaleUpAction = SKAction.scale(to: 1.0, duration: 1.0)
        let sequenceAction = SKAction.sequence([scaleDownAction, scaleUpAction])
        let loopAction = SKAction.repeatForever(sequenceAction)
        loginButtonNode?.run(loopAction)
    }
}
