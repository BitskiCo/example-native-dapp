//
//  AuthScene.swift
//  ExampleNativeDApp
//
//  Created by Patrick Tescher on 5/5/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import SpriteKit
import Bitski

class SKTouchSprite: SKSpriteNode {
    
    var standardTexture: SKTexture?
    var pressedTexture: SKTexture?
    
    var touchHandler: ((SKTouchSprite) -> Void)?
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        self.standardTexture = texture
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.standardTexture = self.texture
        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let texture = pressedTexture {
            self.texture = texture
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if let texture = standardTexture {
            self.texture = texture
            touchHandler?(self)
        }
    }
}

class AuthScene: SKScene {
    var loginButtonNode: SKTouchSprite?

    var bitski: Bitski?

    var signIn: (()->Void)?

    override func sceneDidLoad() {
        super.sceneDidLoad()

        loginButtonNode = childNode(withName: "LoginButton") as? SKTouchSprite
        loginButtonNode?.pressedTexture = SKTexture(imageNamed: "startBtnPressed")
        loginButtonNode?.isUserInteractionEnabled = true
        loginButtonNode?.touchHandler = { _ in
            self.signIn?()
        }
    }
}
