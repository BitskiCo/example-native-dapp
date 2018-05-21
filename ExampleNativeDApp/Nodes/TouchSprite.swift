//
//  TouchSprite.swift
//  ExampleNativeDApp
//
//  Created by Josh Pyles on 5/17/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Foundation
import SpriteKit

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
    
    /// Determine if any of the touches are within the `ButtonNode`.
    private func containsTouches(touches: Set<UITouch>) -> Bool {
        guard let scene = scene else {
            assertionFailure()
            return false
        }
        
        return touches.contains { touch in
            let touchPoint = touch.location(in: scene)
            let touchedNode = scene.atPoint(touchPoint)
            return touchedNode === self || touchedNode.inParentHierarchy(self)
        }
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
        }
        if containsTouches(touches: touches) {
            touchHandler?(self)
        }
    }
}
