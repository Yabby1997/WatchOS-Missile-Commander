//
//  InterfaceController.swift
//  MissileCommander WatchKit Extension
//
//  Created by Seunghun Yang on 2021/06/29.
//

import WatchKit
import Foundation
import SpriteKit

class InterfaceController: WKInterfaceController {

    @IBOutlet weak var skView: WKInterfaceSKScene!
    
    override func awake(withContext context: Any?) {
        let gameScene = GameScene(size: CGSize(width: 600, height: 500))
        gameScene.scaleMode = .aspectFit
        self.skView.presentScene(gameScene)
        self.skView.preferredFramesPerSecond = 60
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }

}
