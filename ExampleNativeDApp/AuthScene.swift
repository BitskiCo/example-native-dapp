//
//  AuthScene.swift
//  ExampleNativeDApp
//
//  Created by Patrick Tescher on 5/5/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import SpriteKit
import BitskiSDK

class AuthScene: SKScene {
    var loginButtonNode: SKNode?

    var bitski: Bitski?

    var signIn: (()->Void)?

    override func sceneDidLoad() {
        super.sceneDidLoad()

        loginButtonNode = childNode(withName: "LoginButton")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        for touch in (touches) {

            let location = touch.location(in: self)
            if atPoint(location) == self.loginButtonNode {
                signIn?()
            }
        }
    }
}
