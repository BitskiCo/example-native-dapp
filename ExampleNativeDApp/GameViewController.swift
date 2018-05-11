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
import BitskiSDK

class GameViewController: UIViewController {

    let bitski = Bitski(clientID: "35a7e890-2f64-4332-b5bc-ee556bde5cf1", redirectURL: URL(string: "bitskiexampledapp://application/callback")!)

    func signIn() {
        bitski.signIn(viewController: self) { (accessToken, error) in
            let web3 = self.bitski.getWeb3(network: "kovan")

            if let scene = GKScene(fileNamed: "BootScene") {
                // Get the SKScene from the loaded GKScene
                if let sceneNode = scene.rootNode as! BootScene? {
                    sceneNode.web3 = web3

                    // Set the scale mode to scale to fit the window
                    sceneNode.scaleMode = .aspectFill

                    // Present the scene
                    if let view = self.view as! SKView? {
                        view.presentScene(sceneNode)

                        view.ignoresSiblingOrder = true

                        view.showsFPS = true
                        view.showsNodeCount = true
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
                                
                // Set the scale mode to scale to fit the window
                sceneNode.scaleMode = .aspectFill
                
                // Present the scene
                if let view = self.view as! SKView? {
                    view.presentScene(sceneNode)
                    
                    view.ignoresSiblingOrder = true
                    
                    view.showsFPS = true
                    view.showsNodeCount = true
                }
            }
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
