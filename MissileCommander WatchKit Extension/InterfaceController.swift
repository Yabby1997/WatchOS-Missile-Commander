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
    
    var gameScene: GameScene?
    
    override func awake(withContext context: Any?) {
        startNewGame()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
    
    @IBAction func handleGesture(gestureRecognizer: WKGestureRecognizer) {
        let bound = gestureRecognizer.objectBounds()
        let location = gestureRecognizer.locationInObject()
        guard let gameScene = self.gameScene else { return }
        if gameScene.isGameOver {
            self.startNewGame()
        } else {
            gameScene.touched(location: CGPoint(x: (location.x / bound.maxX) * 600, y: ((bound.maxY - location.y) / bound.maxY) * 500))
        }
    }
    
    func startNewGame() {
        gameScene =  GameScene(size: CGSize(width: 600, height: 500))
        skView.presentScene(gameScene)
        skView.preferredFramesPerSecond = 60
    }
}
