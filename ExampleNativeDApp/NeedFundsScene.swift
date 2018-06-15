//
//  NeedFundsScene.swift
//  ExampleNativeDApp
//
//  Created by Josh Pyles on 5/14/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Foundation
import SpriteKit
import Web3

class NeedFundsScene: SKScene {
    
    var copyAddressNode: SKNode?
    var requestETHNode: SKNode?
    
    var web3: Web3?
    var currentAddress: EthereumAddress?
    var contract: LimitedMintableNonFungibleToken?
    
    func set(web3: Web3, currentAddress: EthereumAddress, contract: LimitedMintableNonFungibleToken) {
        self.web3 = web3
        self.currentAddress = currentAddress
        self.contract = contract
    }
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        copyAddressNode = childNode(withName: "CopyAddress")
        requestETHNode = childNode(withName: "RequestETH")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        for touch in (touches) {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            if touchedNode == copyAddressNode {
                copyAddress()
            } else if touchedNode == requestETHNode {
                requestETH()
            }
        }
    }
    
    func refreshBalance() {
        guard let web3 = web3, let address = currentAddress else { return }
        web3.eth.getBalance(address: address, block: .latest).done { balance in
            if balance.quantity > 0 {
                self.showBootScene()
            }
        }.catch { error in
            print("Error loading balance", error)
            Logger.log(error: error, context: "Error loading balance")
        }
    }
    
    func requestETH() {
        let url = URL(string: "https://gitter.im/kovan-testnet/faucet")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func copyAddress() {
        if let addressString = currentAddress?.hex(eip55: true) {
            UIPasteboard.general.string = addressString
        }
    }
    
    func showBootScene() {
        guard let web3 = web3, let contract = contract else { return }
        if let scene = BootScene(fileNamed: "BootScene") {
            scene.set(web3: web3, contract: contract)
            self.view?.presentScene(scene)
        }
    }
    
}
