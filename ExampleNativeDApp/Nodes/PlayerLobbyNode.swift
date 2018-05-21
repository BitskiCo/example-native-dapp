//
//  PlayerLobbyNode.swift
//  ExampleNativeDApp
//
//  Created by Josh Pyles on 5/16/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Foundation
import SpriteKit
import BigInt

protocol PlayerLobbyNodeDelegate: class {
    func playerNodeWasTapped(_ node: PlayerLobbyNode)
    func addButtonWasTapped(_ node: PlayerLobbyNode)
}

class PlayerLobbyNode: SKNode {
    
    enum HighlightState {
        case normal
        case selected
        case deselected
    }
    
    enum CharacterState {
        case empty
        case pending
        case normal
    }
    
    private var pedestalNode: SKSpriteNode!
    private var characterNode: SKSpriteNode!
    private var addButtonNode: SKSpriteNode!
    
    private var addButtonAtlas: SKTextureAtlas?
    
    private(set) var characterID: BigUInt?
    
    weak var delegate: PlayerLobbyNodeDelegate?
    
    var characterState: CharacterState = .empty {
        didSet {
            if characterState != oldValue {
                configureForState()
            }
        }
    }
    
    var highlightState: HighlightState = .normal {
        didSet {
            if highlightState != oldValue {
                configureForState()
            }
        }
    }
    
    override init() {
        super.init()
        setupChildNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupChildNodes()
        configureForState()
    }
    
    func setCharacterID(_ id: BigUInt?) {
        characterID = id
        if let id = id {
            let imageIndex = (id % BigUInt(5)) + 1
            let imageName = "character-\(imageIndex)"
            let texture = SKTexture(imageNamed: imageName)
            characterNode.texture = texture
            characterNode.size = texture.size()
        }
        configureForState()
    }
    
    private func setupChildNodes() {
        self.pedestalNode = createPedestal()
        self.characterNode = createCharacter()
        self.addButtonNode = createAddButton()
        configureForState()
    }
    
    private func createPedestal() -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed: "pedestal")
        sprite.size = CGSize(width: 129, height: 45)
        sprite.position = CGPoint(x: 0, y: -30)
        addChild(sprite)
        return sprite
    }
    
    private func createCharacter() -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: nil)
        sprite.position = CGPoint(x: 0, y: 0)
        sprite.alpha = 0
        addChild(sprite)
        return sprite
    }
    
    private func createAddButton() -> SKSpriteNode {
        let defaultTexture = SKTexture(imageNamed: "addPlayerBtnRound")
        let pressedTexture = SKTexture(imageNamed: "addPlayerBtnRoundPressed")
        let atlas = SKTextureAtlas(named: "addPlayer")
        self.addButtonAtlas = atlas
        let sprite = SKTouchSprite(texture: defaultTexture)
        sprite.position = CGPoint(x: 0, y: 10)
        sprite.standardTexture = defaultTexture
        sprite.pressedTexture = pressedTexture
        sprite.touchHandler = { [weak self] _ in
            if let this = self {
                this.delegate?.addButtonWasTapped(this)
            }
        }
        sprite.alpha = 0
        sprite.isUserInteractionEnabled = false
        addChild(sprite)
        return sprite
    }
    
    private let pedestalDefaultTexture = SKTexture(imageNamed: "pedestal")
    private let pedestalActiveTexture = SKTexture(imageNamed: "pedestalActive")
    
    private lazy var pedestalDeactivateAction: SKAction = {
        return SKAction.setTexture(self.pedestalDefaultTexture)
    }()
    
    private lazy var pedestalActivateAction: SKAction = {
        return SKAction.setTexture(self.pedestalActiveTexture)
    }()
    
    private lazy var characterActivateAction: SKAction = {
        return SKAction.fadeAlpha(to: 1, duration: 0.2)
    }()
    
    private lazy var characterDeactivateAction: SKAction = {
        return SKAction.fadeAlpha(to: 0.3, duration: 0.2)
    }()
    
    private lazy var characterPulseAction: SKAction = {
        let fadeOutAction = SKAction.fadeAlpha(to: 0.2, duration: 1.0)
        let fadeInAction = SKAction.fadeAlpha(to: 0.4, duration: 1.0)
        let sequenceAction = SKAction.sequence([fadeInAction, fadeOutAction])
        return SKAction.repeatForever(sequenceAction)
    }()
    
    private lazy var animateAddButtonAction: SKAction = {
        let wait = SKAction.wait(forDuration: 3.0)
        let images = self.addButtonAtlas?.textureNames.sorted().compactMap { self.addButtonAtlas?.textureNamed($0) } ?? []
        let animate = SKAction.animate(with: images, timePerFrame: 0.05)
        let sequenceAction = SKAction.sequence([wait, animate])
        return SKAction.repeatForever(sequenceAction)
    }()
    
    private lazy var addButtonActivateAction: SKAction = {
        return SKAction.fadeIn(withDuration: 0.2)
    }()
    
    private lazy var addButtonDeactivateAction: SKAction = {
        return SKAction.fadeOut(withDuration: 0.2)
    }()
    
    private func configureForState() {
        pedestalNode.removeAllActions()
        characterNode.removeAllActions()
        addButtonNode.removeAllActions()
        
        switch characterState {
        case .empty:
            characterNode.alpha = 0
            addButtonNode.isHidden = false
            addButtonNode.isUserInteractionEnabled = true
            addButtonNode.texture = SKTexture(imageNamed: "addPlayerBtnRound")
            addButtonNode.run(addButtonActivateAction)
            addButtonNode.run(animateAddButtonAction)
        case .normal:
            characterNode.alpha = 1
            addButtonNode.isHidden = true
            addButtonNode.isUserInteractionEnabled = false
        case .pending:
            characterNode.run(characterPulseAction, withKey: "pulse")
            addButtonNode.alpha = 0
            addButtonNode.isUserInteractionEnabled = false
        }
        
        switch highlightState {
        case .normal:
            if characterState != .empty {
                characterNode.run(characterActivateAction)
            }
            pedestalNode.run(pedestalDeactivateAction)
        case .selected:
            if characterState != .empty {
                characterNode.run(characterActivateAction)
            }
            pedestalNode.run(pedestalActivateAction)
        case .deselected:
            addButtonNode.run(addButtonDeactivateAction)
            if characterState != .empty {
                characterNode.run(characterDeactivateAction)
            }
            pedestalNode.run(pedestalDeactivateAction)
        }
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
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if containsTouches(touches: touches) {
            delegate?.playerNodeWasTapped(self)
        }
    }
}
