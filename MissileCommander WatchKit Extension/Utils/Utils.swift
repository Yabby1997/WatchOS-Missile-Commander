
import SpriteKit
import AVFoundation

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

func startNewGame() {
    print("!!!")
//    let skView = SKView(frame: CGRect(x: 0, y: 0, width: 600, height: 500))
//
//    let gameScene = GameScene(size: CGSize(width: 600, height: 500))
//    gameScene.scaleMode = .aspectFit
//    skView.presentScene(gameScene)
//    skView.preferredFramesPerSecond = 60
//    skView.showsFPS = true
//    skView.showsNodeCount = true

//    PlaygroundPage.current.liveView = skView
}

func soundPlayer(sound: String) -> AVAudioPlayer? {
    if let path = Bundle.main.path(forResource: sound, ofType: nil) {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            return audioPlayer
        } catch {
            print("Could not find and play the sound file")
        }
    }
    return nil
}

func getWarheadSize(blastRange: Int) -> Int {
    if blastRange <= 50 {
        return 5
    } else if blastRange <= 150 {
        return 7
    } else {
        return 11
    }
}

func getDistance(from: CGPoint, to: CGPoint) -> CGFloat {
    let xDistance = from.x - to.x
    let yDistance = from.y - to.y
    return sqrt(xDistance * xDistance + yDistance * yDistance)
}

func gacha(probability: Double) -> Bool {
    let randomNumber = Double.random(in: 0...100)
    return randomNumber <= probability
}
