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
import BitskiSDK

class GameViewController: UIViewController {

    let bitski = Bitski(clientID: "35a7e890-2f64-4332-b5bc-ee556bde5cf1", redirectURL: URL(string: "bitskiexampledapp://application/callback")!)
    var tokenContract: LimitedMintableNonFungibleToken?
    
    
    func signIn() {
        bitski.signIn(viewController: self) { (accessToken, error) in
            if let error = error {
                print(error)
            }
            
            let web3 = self.bitski.getWeb3(network: "kovan")
            let contract = LimitedMintableNonFungibleToken(web3: web3)
            
            if let scene = GKScene(fileNamed: "BootScene") {
                // Get the SKScene from the loaded GKScene
                if let sceneNode = scene.rootNode as! BootScene? {
                    sceneNode.set(web3: web3, contract: contract)

                    // Present the scene
                    if let view = self.view as! SKView? {
                        view.presentScene(sceneNode)
                        view.ignoresSiblingOrder = true
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load 'GameScene.sks' as a GKScene. This provides gameplay related content
        // including entities and graphs.
        if let scene = GKScene(fileNamed: "AuthScene") {
            
            // Get the SKScene from the loaded GKScene
            if let sceneNode = scene.rootNode as! AuthScene? {

                sceneNode.signIn = {
                    self.signIn()
                }
                
                // Present the scene
                if let view = self.view as! SKView? {
                    view.presentScene(sceneNode)
                    
                    view.ignoresSiblingOrder = true
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
