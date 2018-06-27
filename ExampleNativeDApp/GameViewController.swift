//
//  GameViewController.swift
//  ExampleNativeDApp
//
//  Created by Patrick Tescher on 5/5/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import BigInt
import Bitski
import Web3

class GameViewController: UIViewController {
    
    var tokenContract: LimitedMintableNonFungibleToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        if Bitski.shared?.isLoggedIn != true {
            showAuthScene()
        } else {
            showBootScene()
        }
        NotificationCenter.default.addObserver(forName: CrewScene.ShowSettingsNotification, object: nil, queue: nil) { notif in
            self.showSettings()
        }
    }
    
    func showSettings() {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        let logoutAction = UIAlertAction(title: "Log Out", style: .default) { _ in
            Bitski.shared?.signOut()
            self.showAuthScene()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showAuthScene() {
        // Load 'GameScene.sks' as a GKScene. This provides gameplay related content
        // including entities and graphs.
        if let scene = GKScene(fileNamed: "AuthScene") {
            
            // Get the SKScene from the loaded GKScene
            if let sceneNode = scene.rootNode as! AuthScene? {
                // Present the scene
                if let view = self.view as! SKView? {
                    let transition = SKTransition.fade(with: .black, duration: 0.4)
                    view.presentScene(sceneNode, transition: transition)
                }
            }
        }
    }
    
    func showBootScene() {
        guard let bitski = Bitski.shared else { return assertionFailure() }
        let web3: Web3
        if let network = CurrentNetwork {
            web3 = bitski.getWeb3(network: network)
        } else {
            web3 = Web3(rpcURL: DevelopmentHost)
        }
        let contract = LimitedMintableNonFungibleToken(web3: web3)
        
        if let scene = GKScene(fileNamed: "BootScene") {
            // Get the SKScene from the loaded GKScene
            if let sceneNode = scene.rootNode as! BootScene? {
                sceneNode.set(web3: web3, contract: contract)
                
                // Present the scene
                if let view = self.view as! SKView? {
                    let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.5)
                    view.presentScene(sceneNode, transition: transition)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let skView = self.view as? SKView, let needFundsScene = skView.scene as? NeedFundsScene {
            needFundsScene.refreshBalance()
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
