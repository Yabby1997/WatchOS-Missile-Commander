import SpriteKit

public class Bomber: SKSpriteNode {
    let gameScene: GameScene
    
    public init(yPosition: CGFloat, fromRight: Bool, flightTime: Double, bombingDuration: Double, blastRange: Int, gameScene: GameScene) {
        self.gameScene = gameScene
        
        super.init(texture: SKTexture(imageNamed: "Sprite/bomber.png"), color: .clear, size: CGSize(width: 50, height: 30))
        self.color = .red
        self.colorBlendFactor = 1.0
        if !fromRight {
            self.xScale = self.xScale * -1
        }
        
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.categoryBitMask = enemyBomberCategory
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.usesPreciseCollisionDetection = true
        
        self.position = CGPoint(x: fromRight ? 600 : 0, y: yPosition)
        
        flyThrough(fromRight: fromRight, flightTime: flightTime)
        attack(fromRight: fromRight, bombingDuration: bombingDuration, blastRange: blastRange)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func flyThrough(fromRight: Bool, flightTime: Double) {
        let actionMove = SKAction.move(to: CGPoint(x: fromRight ? 0 : 600, y: self.position.y), duration: TimeInterval(flightTime))
        let actionRemove = SKAction.removeFromParent()
        self.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func attack(fromRight: Bool, bombingDuration: Double, blastRange: Int) {
        let wait = SKAction.wait(forDuration: bombingDuration)
        let bomb = SKAction.run {
            let momentum = CGFloat.random(in: 100...200)
            let targetCoordinate = CGPoint(x: self.position.x + (fromRight ? -1 * momentum : momentum), y: 25)
            let distance = getDistance(from: self.position, to: targetCoordinate)
            let warhead = EnemyWarhead(position: self.position,
                                       distance: distance,
                                       velocity: 75,
                                       targetCoordinate: targetCoordinate,
                                       blastRange: blastRange,
                                       gameScene: self.gameScene)
            self.gameScene.addChild(warhead)
        }
        
        self.run(SKAction.repeatForever(SKAction.sequence([bomb, wait])))
    }
}
