import SpriteKit

public class Explosion: SKSpriteNode {
    let blastRange: Int
    let gameScene: GameScene
    
    init(position: CGPoint, blastRange: Int, gameScene: GameScene) {
        self.blastRange = blastRange
        self.gameScene = gameScene
        super.init(texture: SKTexture(imageNamed: "explosion_\(blastRange).png"), color: .clear, size: CGSize(width: blastRange, height: blastRange))
        self.position = position
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.contactTestBitMask = enemyWarheadCategory | playerSiloCategory | playerCityCategory | enemyBomberCategory
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.usesPreciseCollisionDetection = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
