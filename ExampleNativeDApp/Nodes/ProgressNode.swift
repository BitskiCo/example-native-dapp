//
//  ProgressNode.swift
//  ExampleNativeDApp
//
//  Created by Josh Pyles on 5/16/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Foundation
import SpriteKit

class ProgressNode: SKNode {
    
    var backgroundNode: SKSpriteNode?
    var progressNode: SKSpriteNode?
    
    var progress: CGFloat = 0 {
        didSet {
            if progress != oldValue {
                configureProgress()
            }
        }
    }
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        backgroundNode = childNode(withName: "Empty") as? SKSpriteNode
        progressNode = childNode(withName: "Full") as? SKSpriteNode
        let textureSize = SKTexture(imageNamed: "progressFull").size()
        let centerRect = CGRect(x: 9 / textureSize.width, y: 0, width: (textureSize.width - 18) / textureSize.width, height: 1)
        progressNode?.centerRect = centerRect
        backgroundNode?.centerRect = centerRect
        progressNode?.size.width = 0
    }
    
    private func configureProgress() {
        let width = self.backgroundNode!.size.width * progress
        progressNode?.run(SKAction.resize(toWidth: width, duration: 0.1))
    }
    
}
