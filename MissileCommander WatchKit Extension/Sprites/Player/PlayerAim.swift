import SpriteKit

public class PlayerAim: SKSpriteNode {
    
    public init(position: CGPoint, duration: TimeInterval) {
        super.init(texture: SKTexture(imageNamed: "aim.png"), color: .clear, size: CGSize(width: 15, height: 15))
        self.position = position
        self.zPosition = 10
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.removeFromParent()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
