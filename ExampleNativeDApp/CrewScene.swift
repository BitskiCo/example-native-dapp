//
//  CrewScene.swift
//  ExampleNativeDApp
//
//  Created by Patrick Tescher on 5/6/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import SpriteKit
import Bitski
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

class CrewScene: SKScene, PlayerLobbyNodeDelegate {
    
    private (set) var tokens = [BigUInt]()
    private var web3: Web3?
    var tokenContract: LimitedMintableNonFungibleToken?
    var currentAccount: EthereumAddress?
    
    var getMoreNode: SKTouchSprite?
    var removeButtonNode: SKTouchSprite?
    var transactionNode: SKNode?
    
    static let ShowSettingsNotification = Notification.Name(rawValue: "ShowSettings")
    
    var currentTransaction: TransactionWatcher?
    
    private var sprites: [PlayerLobbyNode] = []
    
    public func set(tokens: [BigUInt], web3: Web3, currentAccount: EthereumAddress, contract: LimitedMintableNonFungibleToken) {
        self.tokens = tokens
        self.web3 = web3
        self.tokenContract = contract
        self.currentAccount = currentAccount
        
        if tokens.count >= 5 {
            getMoreNode?.texture = SKTexture(imageNamed: "squadFullBtn")
            getMoreNode?.isUserInteractionEnabled = false
        } else {
            getMoreNode?.texture = getMoreNode?.standardTexture
            getMoreNode?.isUserInteractionEnabled = true
        }
        
        updateTitle()
        
        for (n, token) in tokens.enumerated() {
            let node = childNode(withName: "position\(n + 1)") as? PlayerLobbyNode
            node?.setCharacterID(token)
            node?.characterState = .normal
        }
    }
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        transactionNode = childNode(withName: "transaction")
        transactionNode?.isHidden = true
        sprites = children.compactMap { $0 as? PlayerLobbyNode }
        
        let settingsButtonNode = childNode(withName: "//Settings") as? SKTouchSprite
        settingsButtonNode?.pressedTexture = SKTexture(imageNamed: "settingsButtonPressed")
        settingsButtonNode?.touchHandler = { _ in
            NotificationCenter.default.post(name: CrewScene.ShowSettingsNotification, object: nil)
        }
        
        removeButtonNode = childNode(withName: "//DeleteButton") as? SKTouchSprite
        removeButtonNode?.pressedTexture = SKTexture(imageNamed: "deleteBtnPressed")
        removeButtonNode?.touchHandler = { [weak self] _ in
            if let character = self?.selectedGuy?.characterID {
                self?.selectedGuy?.characterState = .pending
                self?.deletingCharacter = self?.selectedGuy
                self?.delete(tokenID: character)
            }
        }
        removeButtonNode?.isUserInteractionEnabled = false
        
        for sprite in sprites {
            sprite.delegate = self
            sprite.isUserInteractionEnabled = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(transactionStatusWasUpdated(notification:)), name: TransactionWatcher.StatusDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveEvent(notification:)), name: TransactionWatcher.DidReceiveEvent, object: nil)
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        updateLayout(view: view)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard let view = view else { return }
        updateLayout(view: view)
    }
    
    func updateTitle() {
        if let selectedID = selectedGuy?.characterID {
            setTitle("Guy #\(selectedID)")
        } else if tokens.count == 0 {
            setTitle("You don't have any guys yet!")
        } else if tokens.count == 1 {
            setTitle("You have one guy")
        } else if tokens.count == 5 {
            setTitle("You have a complete crew! Yay!")
        } else {
            setTitle("You have \(tokens.count) guys")
        }
    }
    
    func updateLayout(view: UIView) {
        if let titleNode = childNode(withName: "title") {
            let topInset = view.safeAreaInsets.top
            let height = view.bounds.height
            let y = (height / 2) - topInset
            titleNode.position.y = y
        }
        
        if let contextNode = childNode(withName: "Context") as? SKLabelNode {
            let topInset = view.safeAreaInsets.top
            let titleBarOffset = childNode(withName: "title")?.calculateAccumulatedFrame().height ?? 0
            let totalTopOffset = topInset + titleBarOffset + 20
            let y = (view.bounds.height / 2) - totalTopOffset
            contextNode.position.y = y
            contextNode.preferredMaxLayoutWidth = view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right - 32
            contextNode.numberOfLines = 0
            contextNode.lineBreakMode = .byCharWrapping
            contextNode.horizontalAlignmentMode = .center
        }
        
        if let actionsNode = childNode(withName: "actions") {
            let bottomInset = view.safeAreaInsets.bottom
            let height = view.bounds.height
            let y = (height / -2) + bottomInset
            actionsNode.position.y = y
        }
        
        if let transactionNode = transactionNode {
            let bottomInset = view.safeAreaInsets.bottom
            let height = view.bounds.height
            let y = (height / -2) + bottomInset
            transactionNode.position.y = y
        }
    }
    
    func getMore() {
        guard let contract = tokenContract, let currentAccount = currentAccount else {
            return assertionFailure()
        }
        
        resetGuys()
        
        for sprite in sprites {
            sprite.isUserInteractionEnabled = false
        }
        
        firstly {
            contract.mintNewToken(from: currentAccount)
        }.done { id, hash in
            self.pendingCharacter?.setCharacterID(id)
            self.pendingCharacter?.characterState = .pending
            (self.childNode(withName: "//LoadingText") as? SKLabelNode)?.text = "Minting Token..."
            self.showTransaction(transactionHash: hash, eventsToWatch: contract.events)
        }.catch { error in
            self.pendingCharacter?.setCharacterID(nil)
            self.pendingCharacter?.characterState = .empty
            for sprite in self.sprites {
                sprite.isUserInteractionEnabled = true
            }
            Logger.log(error: error, context: "Error minting token")
        }
    }
    
    func delete(tokenID: BigUInt) {
        guard let contract = tokenContract, let currentAccount = currentAccount else {
            return assertionFailure()
        }
        
        resetGuys()
        
        sprites.forEach { sprite in
            sprite.isUserInteractionEnabled = false
        }
        
        firstly {
            contract.deleteToken(from: currentAccount, tokenID: tokenID)
        }.done { hash in
            (self.childNode(withName: "//LoadingText") as? SKLabelNode)?.text = "Deleting Token..."
            self.showTransaction(transactionHash: hash, eventsToWatch: contract.events)
        }.catch { error in
            self.deletingCharacter?.characterState = .normal
            self.sprites.forEach { sprite in
                sprite.isUserInteractionEnabled = true
            }
            Logger.log(error: error, context: "Error deleting token")
        }
    }
    
    func showTransaction(transactionHash: EthereumData, eventsToWatch: [SolidityEvent]) {
        guard let web3 = web3 else { return assertionFailure() }
        childNode(withName: "actions")?.isHidden = true
        transactionNode?.isHidden = false
        configureForTransaction(status: .pending)
        currentTransaction = TransactionWatcher(transactionHash: transactionHash, web3: web3)
        eventsToWatch.forEach { event in
            currentTransaction?.startWatching(for: event)
        }
        currentTransaction?.expectedConfirmations = 3
    }
    
    func setTitle(_ string: String) {
        if let titleNode = childNode(withName: "Context") as? SKLabelNode {
            titleNode.text = string
        }
    }
    
    var pendingCharacter: PlayerLobbyNode?
    var deletingCharacter: PlayerLobbyNode?
    
    var selectedGuy: PlayerLobbyNode? {
        didSet {
            if let selectedGuy = selectedGuy {
                for sprite in sprites {
                    if sprite == selectedGuy {
                        sprite.highlightState = .selected
                    } else {
                        sprite.highlightState = .deselected
                    }
                }
                removeButtonNode?.alpha = 1
                removeButtonNode?.isUserInteractionEnabled = true
                updateTitle()
            } else {
                resetGuys()
            }
        }
    }
    
    func resetGuys() {
        for sprite in sprites {
            sprite.highlightState = .normal
        }
        removeButtonNode?.alpha = 0
        removeButtonNode?.isUserInteractionEnabled = false
        updateTitle()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        selectedGuy = nil
    }
    
    func playerNodeWasTapped(_ node: PlayerLobbyNode) {
        if node.characterState != .empty {
            selectedGuy = node
        }
    }
    
    func addButtonWasTapped(_ node: PlayerLobbyNode) {
        if node.characterState == .empty {
            pendingCharacter = node
            getMore()
        }
    }
    
    func updateProgress(progress: CGFloat) {
        let progressNode = childNode(withName: "//Progress") as? ProgressNode
        progressNode?.progress = progress
    }
    
    func configureForTransaction(status: TransactionWatcher.Status) {
        switch status {
        case .pending:
            setTitle("Transaction Submitted")
            updateProgress(progress: 0)
        case .approved(let times):
            updateProgress(progress: CGFloat(times) / 3)
            setTitle("Waiting for Approval (\(times)/3)")
        case .successful:
            updateProgress(progress: 1)
            if let character = self.deletingCharacter {
                if let tokenID = character.characterID {
                    tokens = tokens.filter { $0 != tokenID }
                }
                character.setCharacterID(nil)
                character.characterState = .empty
                selectedGuy = nil
                deletingCharacter = nil
            } else if let character = self.pendingCharacter {
                //TODO: parse logs for events
                if let tokenID = character.characterID {
                    tokens.append(tokenID)
                }
                character.characterState = .normal
                pendingCharacter = nil
            }
            currentTransaction = nil
            sprites.forEach { sprite in
                sprite.isUserInteractionEnabled = true
            }
            updateTitle()
            transactionNode?.isHidden = true
            childNode(withName: "actions")?.isHidden = false
        case .failed:
            if let character = self.deletingCharacter {
                character.characterState = .normal
            }
            if let character = self.pendingCharacter {
                character.setCharacterID(nil)
                character.characterState = .empty
            }
            sprites.forEach { sprite in
                sprite.isUserInteractionEnabled = true
            }
            setTitle("Transaction Failed")
            transactionNode?.isHidden = true
            childNode(withName: "actions")?.isHidden = false
            currentTransaction = nil
        }
    }
    
    @objc func transactionStatusWasUpdated(notification: Notification) {
        if let status = currentTransaction?.status {
            configureForTransaction(status: status)
        }
    }
    
    @objc func didReceiveEvent(notification: Notification) {
        if let event = notification.userInfo?[TransactionWatcher.MatchedEventKey] {
            print("Received event", event)
        }
    }
}
