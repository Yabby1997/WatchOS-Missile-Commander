//
//  GameScene.swift
//  MissileCommander
//
//  Created by Seunghun Yang on 2021/06/28.
//

import SpriteKit
import WatchKit

public class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Labels
    
    lazy var scoreLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "PressStart2P")
        label.fontSize = 30
        label.fontColor = SKColor.white
        label.position = CGPoint(x: self.frame.midX, y: 520)
        label.zPosition = 50
        return label
    }()
    
    lazy var timeLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "PressStart2P")
        label.fontSize = 30
        label.fontColor = SKColor.white
        label.position = CGPoint(x: self.frame.midX, y: 560)
        label.zPosition = 50
        let countOneSecond = SKAction.run { self.time = self.time + 1 }
        let waitOneSecond = SKAction.wait(forDuration: 1)
        self.run(SKAction.repeatForever(SKAction.sequence([waitOneSecond, countOneSecond])), withKey: "countSeconds")
        return label
    }()
    
    // MARK: - Score and Time
    private var playerScore: UInt64 = 0 {
        didSet {
            self.scoreLabel.text = "\(playerScore)"
        }
    }
    
    private var time: Int = 0 {
        didSet {
            self.setTimeLabel(alwaysDisplayColon: false)
            if(time % 30 == 0) {
                self.setDifficulty(time: time)
            }
        }
    }
    
    // MARK: - Player buildings
    private let locations: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
    
    private var silos: [Silo] = []
    private var siloLocation: [Int] = [1, 5, 9] {
        didSet {
            if siloLocation.isEmpty {
                self.gameOver()
            }
        }
    }
    
    private var cities: [City] = []
    private var cityLocation: [Int] = [2, 3, 4, 6, 7, 8] {
        didSet {
            if cityLocation.isEmpty {
                self.gameOver()
            }
        }
    }
    
    private var occupiedLocations: [Int] {
        return self.cityLocation + self.siloLocation
    }
    
    private var availableLocations: [Int] {
        return self.locations.difference(from: self.occupiedLocations)
    }

    private var randomTargetLocation: Int? {
        if self.occupiedLocations.isEmpty {
            return nil
        } else {
            return self.occupiedLocations.randomElement()
        }
    }
    
    // MARK: - Game Status
    var isGameOver: Bool = false
    private var explosionChainingDelay: Double = 0.2
    
    private var isWarheadRaidOn: Bool = false {
        didSet {
            self.warheadRaid()
        }
    }
    private var warheadRaidTimer: Timer!
    private var warheadPerRaid: Int = 0
    private var warheadRaidInterval: Double = 10
    
    private var isBomberRaidOn: Bool = false {
        didSet {
            self.bomberRaid()
        }
    }
    private var bomberRaidTimer: Timer!
    private var bomberPerRaid: Int = 0
    private var bomberRaidInterval: Double = 30
    
    private var isTzarRaidOn: Bool = false {
        didSet {
            self.tzarRaid()
        }
    }
    private var tzarRaidTimer: Timer!
    private var tzarPerRaid: Int = 1
    private var tzarRaidInterval: Double = 15
    
    private var enemyWarheadVelocityCandidates: [Int] = [50, 55]
    private var enemyWarheadBlastRangeCandidates: [Int] = [40, 45]
    
    private var playerExplosionWarheadDropProbability: Double = 3
    private var enemyExplosionWarheadDropProbability: Double = 5
    private var playerExplosionTzarDropProbability: Double = 5
    private var enemyExplosionTzarDropProbability: Double = 8
    private var playerExplosionBomberDropProbability: Double = 5
    private var enemyExplosionBomberDropProbability: Double = 8
    
    // MARK: - Player Status
    static let itemScore: UInt64 = 10000
    
    static let initialPlayerMissileCapacity: Int = 2
    static let initialPlayerMissileReloadTime: Double = 3.0
    static let initialPlayerMissileVelocity: CGFloat = 250
    static let initialPlayerExplosionBlastRange: Int = 40
    static let initialGlobalExplosionDuration: Double = 0.5
    
    static let maximumPlayerMissileCapacity: Int = 5
    static let minimumPlayerMissileReloadTime: Double = 1.0
    static let maximumPlayerMissileVelocity: CGFloat = 450
    static let maximumPlayerExplosionBlastRange: Int = 65
    static let maximumGlobalExplosionDuration: Double = 1.5
    
    static let missileCapacityUpgradeAmount: Int = (maximumPlayerMissileCapacity - initialPlayerMissileCapacity) / 3
    static let missileReloadTimeUpgradeAmount: Double = (minimumPlayerMissileReloadTime - initialPlayerMissileReloadTime) / 5
    static let missileVelocityUpgradeAmount: CGFloat = (maximumPlayerMissileVelocity - initialPlayerMissileVelocity) / 5
    static let explosionBlastRangeUpgradeAmount: Int = (maximumPlayerExplosionBlastRange - initialPlayerExplosionBlastRange) / 5
    static let explosionDurationUpgradeAmount: Double = (maximumGlobalExplosionDuration - initialGlobalExplosionDuration) / 5
    
    private var playerMissileCapacity: Int = initialPlayerMissileCapacity
    private var playerMissileReloadTime: Double = initialPlayerMissileReloadTime
    private var playerMissileVelocity: CGFloat = initialPlayerMissileVelocity
    private var playerExplosionBlastRange: Int = initialPlayerExplosionBlastRange
    private var globalExplosionDuration: Double = initialGlobalExplosionDuration
    
    public var isPlayerMissileCapacityUpgradable: Bool {
        self.playerMissileCapacity < GameScene.maximumPlayerMissileCapacity
    }
    public var isPlayerMissileReloadTimeUpgradable: Bool {
        self.playerMissileReloadTime > GameScene.minimumPlayerMissileReloadTime
    }
    public var isPlayerMissileVelocityUpgradable: Bool {
        self.playerMissileVelocity < GameScene.maximumPlayerMissileVelocity
    }
    public var isPlayerExplosionBlastRangeUpgradable: Bool {
        self.playerExplosionBlastRange < GameScene.maximumPlayerExplosionBlastRange
    }
    public var isGlobalExplosionDurationUpgradable: Bool {
        self.globalExplosionDuration < GameScene.maximumGlobalExplosionDuration
    }
    public var isPlayerCityRebuildable: Bool {
        return self.cities.count < 6
    }
    public var isPlayerSiloRebuildable: Bool {
        return self.silos.count < 3
    }
    
    func getMissileCapacity() -> Int {
        return self.playerMissileCapacity
    }
    
    func getMissileReloadTime() -> Double {
        return self.playerMissileReloadTime
    }
    
    func getMissileVelocity() -> CGFloat {
        return self.playerMissileVelocity
    }
    
    func getExplosionBlastRange() -> Int {
        return self.playerExplosionBlastRange
    }
    
    func getExplosionDuration() -> Double {
        return self.globalExplosionDuration
    }
    
    // MARK: - Entrypoint to GameScene
    
    public override func sceneDidLoad() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.0
        
        self.backgroundColor = .black
        self.physicsWorld.contactDelegate = self
        
        self.addChild(self.scoreLabel)
        self.addChild(self.timeLabel)
        generateSilos()
        generateCities()
        
        self.playerScore = 0
        self.time = 0
    }
    
    // MARK: - Collision
    public func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }

        switch collision {
        
        case collisionBetweenEnemyWarheadAndPlayerExplosion:
            let enemyWarhead = (contact.bodyA.categoryBitMask == enemyWarheadCategory ? nodeA : nodeB) as! EnemyWarhead
            enemyWarhead.removeFromParent()
            let blastRange = enemyWarhead.blastRange
            self.playerScore = self.playerScore + UInt64(blastRange)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + explosionChainingDelay) {
                let newExplosion = EnemyExplosion(position: contact.contactPoint, blastRange: blastRange, chainingCombo: 1, gameScene: self)
                self.addChild(newExplosion)
                
                if blastRange == 300 {
                    self.dropRandomItem(probability: self.playerExplosionTzarDropProbability, position: contact.contactPoint)
                } else {
                    self.dropRandomItem(probability: self.playerExplosionWarheadDropProbability, position: contact.contactPoint)
                }
            }
            
        case collisionBetweenEnemyWarheadAndEnemyExplosion:
            let enemyWarhead = (contact.bodyA.categoryBitMask == enemyWarheadCategory ? nodeA : nodeB) as! EnemyWarhead
            let enemyExplosion = (contact.bodyA.categoryBitMask == enemyExplosionCategory ? nodeA : nodeB) as! EnemyExplosion
            enemyWarhead.removeFromParent()
            let blastRange = enemyWarhead.blastRange
            let combo = enemyExplosion.chainingCombo
            self.playerScore = self.playerScore + UInt64(blastRange * (combo * 10) * (combo < 5 ? 1 : 10))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + explosionChainingDelay) {
                let newExplosion = EnemyExplosion(position: contact.contactPoint, blastRange: blastRange, chainingCombo: combo == 0 ? 0 : combo + 1, gameScene: self)
                self.generateComboLabel(combo: combo, position: contact.contactPoint, range: blastRange)
                self.addChild(newExplosion)
                
                if combo != 0 {
                    if blastRange == 300 {
                        self.dropRandomItem(probability: self.enemyExplosionTzarDropProbability, position: contact.contactPoint)
                    } else {
                        self.dropRandomItem(probability: self.enemyExplosionWarheadDropProbability, position: contact.contactPoint)
                    }
                }
            }
            
            
        case collisionBetweenEnemyBomberAndPlayerExplosion:
            let bomber = (contact.bodyA.categoryBitMask == enemyBomberCategory ? nodeA : nodeB) as! Bomber
            bomber.removeFromParent()
            let blastRange = 150
            self.playerScore = self.playerScore + UInt64(blastRange)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + explosionChainingDelay) {
                let newExplosion = EnemyExplosion(position: contact.contactPoint, blastRange: blastRange, chainingCombo: 1, gameScene: self)
                self.addChild(newExplosion)
                self.dropRandomItem(probability: self.playerExplosionBomberDropProbability, position: contact.contactPoint)
            }
            
        case collisionBetweenEnemyBomberAndEnemyExplosion:
            let bomber = (contact.bodyA.categoryBitMask == enemyBomberCategory ? nodeA : nodeB) as! Bomber
            let enemyExplosion = (contact.bodyA.categoryBitMask == enemyExplosionCategory ? nodeA : nodeB) as! EnemyExplosion
            bomber.removeFromParent()
            let blastRange = 150
            let combo = enemyExplosion.chainingCombo
            self.playerScore = self.playerScore + UInt64(blastRange * (combo * 10) * (combo < 5 ? 1 : 10))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + explosionChainingDelay) {
                let newExplosion = EnemyExplosion(position: contact.contactPoint, blastRange: blastRange, chainingCombo: combo == 0 ? 0 : combo + 1, gameScene: self)
                self.generateComboLabel(combo: combo, position: contact.contactPoint, range: blastRange)
                self.addChild(newExplosion)
                
                if combo != 0 {
                    self.dropRandomItem(probability: self.enemyExplosionBomberDropProbability, position: contact.contactPoint)
                }
            }
            
        case collisionBetweenPlayerSiloAndEnemyExplosion, collisionBetweenPlayerSiloAndPlayerExplosion:
            let silo = (contact.bodyA.categoryBitMask == playerSiloCategory ? nodeA : nodeB) as! Silo
            removeSiloFromGameScene(targetSilo: silo)
            silo.removeFromParent()
            
        case collisionBetweenPlayerCityAndEnemyExplosion, collisionBetweenPlayerCityAndPlayerExplosion:
            let city = (contact.bodyA.categoryBitMask == playerCityCategory ? nodeA : nodeB) as! City
            removeCityFromGameScene(targetCity: city)
            city.removeFromParent()
            
        case collisionBetweenAmmunitionItemAndPlayerExplosion:
            let ammunition = (contact.bodyA.categoryBitMask == ammunitionItemCategory ? nodeA : nodeB) as! AmmunitionItem
            let explosion = (contact.bodyA.categoryBitMask == playerExplosionCategory ? nodeA : nodeB) as! PlayerExplosion
            let blastRange = explosion.blastRange
            
            self.generateItemLabel(upgradable: self.isPlayerMissileCapacityUpgradable, itemName: "Ammunition Capacity", color: SKColor.yellow, position: contact.contactPoint, range: blastRange)
            self.upgradePlayerMissileCapacity()
            ammunition.removeFromParent()
            
        case collisionBetweenBlastItemAndPlayerExplosion:
            let blast = (contact.bodyA.categoryBitMask == blastItemCategory ? nodeA : nodeB) as! BlastItem
            let explosion = (contact.bodyA.categoryBitMask == playerExplosionCategory ? nodeA : nodeB) as! PlayerExplosion
            let blastRange = explosion.blastRange
            
            self.generateItemLabel(upgradable: self.isPlayerExplosionBlastRangeUpgradable, itemName: "Explosion Blast", color: SKColor.red, position: contact.contactPoint, range: blastRange)
            self.upgradePlayerExplosionBlastRange()
            blast.removeFromParent()
            
        case collisionBetweenDurationItemAndPlayerExplosion:
            let duration = (contact.bodyA.categoryBitMask == durationItemCategory ? nodeA : nodeB) as! DurationItem
            let explosion = (contact.bodyA.categoryBitMask == playerExplosionCategory ? nodeA : nodeB) as! PlayerExplosion
            let blastRange = explosion.blastRange
            
            self.generateItemLabel(upgradable: self.isGlobalExplosionDurationUpgradable, itemName: "Explosion Duration", color: SKColor.orange, position: contact.contactPoint, range: blastRange)
            self.upgradeGlobalExplosionDuration()
            duration.removeFromParent()
            
        case collisionBetweenReloadItemAndPlayerExplosion:
            let reload = (contact.bodyA.categoryBitMask == reloadItemCategory ? nodeA : nodeB) as! ReloadItem
            let explosion = (contact.bodyA.categoryBitMask == playerExplosionCategory ? nodeA : nodeB) as! PlayerExplosion
            let blastRange = explosion.blastRange
            
            self.generateItemLabel(upgradable: self.isPlayerMissileReloadTimeUpgradable, itemName: "Reload Time", color: SKColor.blue, position: contact.contactPoint, range: blastRange)
            self.upgradePlayerMissileReloadTime()
            reload.removeFromParent()
            
        case collisionBetweenVelocityItemAndPlayerExplosion:
            let velocity = (contact.bodyA.categoryBitMask == velocityItemCategory ? nodeA : nodeB) as! VelocityItem
            let explosion = (contact.bodyA.categoryBitMask == playerExplosionCategory ? nodeA : nodeB) as! PlayerExplosion
            let blastRange = explosion.blastRange
            
            self.generateItemLabel(upgradable: self.isPlayerMissileVelocityUpgradable, itemName: "Missile Velocity", color: SKColor.green, position: contact.contactPoint, range: blastRange)
            self.upgradePlayerMissileVelocity()
            velocity.removeFromParent()
            
        case collisionBetweenCityItemAndPlayerExplosion:
            let city = (contact.bodyA.categoryBitMask == cityItemCategory ? nodeA : nodeB) as! CityItem
            let explosion = (contact.bodyA.categoryBitMask == playerExplosionCategory ? nodeA : nodeB) as! PlayerExplosion
            let blastRange = explosion.blastRange
            
            self.generateItemLabel(upgradable: self.isPlayerCityRebuildable, itemName: "New City", color: SKColor.magenta, position: contact.contactPoint, range: blastRange)
            self.rebuildPlayerCity(position: contact.contactPoint)
            city.removeFromParent()
            
        case collisionBetweenSiloItemAndPlayerExplosion:
            let silo = (contact.bodyA.categoryBitMask == siloItemCategory ? nodeA : nodeB) as! SiloItem
            let explosion = (contact.bodyA.categoryBitMask == playerExplosionCategory ? nodeA : nodeB) as! PlayerExplosion
            let blastRange = explosion.blastRange
            
            self.generateItemLabel(upgradable: self.isPlayerSiloRebuildable, itemName: "New Silo", color: SKColor.cyan, position: contact.contactPoint, range: blastRange)
            self.rebuildPlayerSilo(position: contact.contactPoint)
            silo.removeFromParent()
            
        default:
            break
        }
    }
    
    // MARK: - Player Status Related Methods
    func upgradePlayerMissileCapacity() {
        if self.isPlayerMissileCapacityUpgradable {
            self.playerMissileCapacity += GameScene.missileCapacityUpgradeAmount
        } else {
            self.playerScore += GameScene.itemScore
        }
        self.reloadAllSilos()
    }
    
    func upgradePlayerMissileVelocity() {
        if self.isPlayerMissileVelocityUpgradable {
            self.playerMissileVelocity += GameScene.missileVelocityUpgradeAmount
        } else {
            self.playerScore += GameScene.itemScore
            self.reloadAllSilos()
        }
    }
    
    func upgradePlayerMissileReloadTime() {
        if self.isPlayerMissileReloadTimeUpgradable {
            self.playerMissileReloadTime += GameScene.missileReloadTimeUpgradeAmount
        } else {
            self.playerScore += GameScene.itemScore
            self.reloadAllSilos()
        }
    }
    
    func upgradePlayerExplosionBlastRange() {
        if self.isPlayerExplosionBlastRangeUpgradable {
            self.playerExplosionBlastRange += GameScene.explosionBlastRangeUpgradeAmount
        } else {
            self.playerScore += GameScene.itemScore
            self.reloadAllSilos()
        }
    }
    
    func upgradeGlobalExplosionDuration() {
        if self.isGlobalExplosionDurationUpgradable {
            self.globalExplosionDuration += GameScene.explosionDurationUpgradeAmount
        } else {
            self.playerScore += GameScene.itemScore
            self.reloadAllSilos()
        }
    }
    
    func rebuildPlayerCity(position: CGPoint) {
        if self.isPlayerCityRebuildable {
            guard let location = self.getClosestAvailableLocation(targetCoordinate: position) else { return }
            let coordinate = self.calculateActualCoordinateOfLocation(location: location)
            let city = City(position: coordinate)
            cities.append(city)
            cityLocation.append(location)
            self.addChild(city)
        } else {
            self.playerScore += GameScene.itemScore
            self.reloadAllSilos()
        }
    }
    
    func rebuildPlayerSilo(position: CGPoint) {
        if self.isPlayerSiloRebuildable {
            guard let location = self.getClosestAvailableLocation(targetCoordinate: position) else { return }
            let coordinate = self.calculateActualCoordinateOfLocation(location: location)
            let silo = Silo(position: coordinate, gameScene: self)
            silos.append(silo)
            siloLocation.append(location)
            self.addChild(silo)
        } else {            self.playerScore += GameScene.itemScore
            self.reloadAllSilos()
        }
    }
    
    
    // MARK: - Enemy Raid Methods
    func warheadRaid() {
        if !isGameOver && isWarheadRaidOn {
            warheadRaidTimer?.invalidate()
            warheadRaidTimer = Timer.scheduledTimer(timeInterval: TimeInterval(self.warheadRaidInterval), target: self, selector: #selector(generateEnemyWarhead), userInfo: nil, repeats: true)
        }
    }
    
    func bomberRaid() {
        if !isGameOver && isBomberRaidOn {
            bomberRaidTimer?.invalidate()
            bomberRaidTimer = Timer.scheduledTimer(timeInterval: TimeInterval(self.bomberRaidInterval), target: self, selector: #selector(generateEnemyBomber), userInfo: nil, repeats: true)
        }
    }
    
    func tzarRaid() {
        if !isGameOver && isTzarRaidOn {
            tzarRaidTimer?.invalidate()
            tzarRaidTimer = Timer.scheduledTimer(timeInterval: TimeInterval(self.tzarRaidInterval), target: self, selector: #selector(generateEnemyTzar), userInfo: nil, repeats: true)
        }
    }
    
    
    // MARK: - Player click input
    func touched(location: CGPoint) {
        guard let closestAvailableSiloInfo = getClosestAvailableSiloInfo(targetCoordinate: location) else { return }
        let silo = closestAvailableSiloInfo.0
        let distance = closestAvailableSiloInfo.1
        silo.shoot(coordinate: location, distance: distance)
    }
    
    // MARK: - Building related methods
    func getClosestAvailableSiloInfo(targetCoordinate: CGPoint) -> (Silo, CGFloat)? {
        var closestDistance: CGFloat = 10_000
        var closestSilo: Silo?
        
        for silo in self.silos {
            if silo.isLoaded {
                let currentDistance = getDistance(from: silo.position, to: targetCoordinate)
                if currentDistance.isLess(than: closestDistance) {
                    closestDistance = currentDistance
                    closestSilo = silo
                }
            }
        }
        return (closestSilo, closestDistance) as? (Silo, CGFloat)
    }
    
    func getClosestAvailableLocation(targetCoordinate: CGPoint) -> Int? {
        var closestDistance: CGFloat = 10_000
        var closestLocation: Int?
        
        for location in self.availableLocations {
            let candidatePosition = self.calculateActualCoordinateOfLocation(location: location)
            let candidateDistance = getDistance(from: candidatePosition, to: targetCoordinate)
            if candidateDistance < closestDistance {
                closestLocation = location
                closestDistance = candidateDistance
            }
        }
        return closestLocation
    }
    
    func removeSiloFromGameScene(targetSilo: Silo) {
        guard let targetIndex = self.silos.firstIndex(of: targetSilo) else { return }
        self.silos.remove(at: targetIndex)
        self.siloLocation.remove(at: targetIndex)
    }
    
    func removeCityFromGameScene(targetCity: City) {
        guard let targetIndex = self.cities.firstIndex(of: targetCity) else { return }
        self.cities.remove(at: targetIndex)
        self.cityLocation.remove(at: targetIndex)
    }
    
    // MARK: - Game related methods
    func calculateActualCoordinateOfLocation(location: Int, usePreciseLocation: Bool = true) -> CGPoint {
        let xCoordinate = CGFloat(location * 50) + (usePreciseLocation ? 0 : CGFloat.random(in: -30...30))
        let yCoordinate = CGFloat(25)
        return CGPoint(x: xCoordinate, y: yCoordinate)
    }
    
    func reloadAllSilos() {
        for silo in self.silos {
            silo.numOfLoadedMissiles = self.playerMissileCapacity
        }
    }
    
    func score(amount: UInt64) {
        self.playerScore = self.playerScore + amount
    }
    
    func setTimeLabel(alwaysDisplayColon: Bool) {
        let minutes = Int(self.time / 60)
        let seconds = Int(self.time - minutes * 60)
        
        if minutes > 0 {
            self.timeLabel.text = (seconds % 2 == 0 || alwaysDisplayColon) ? String(format: "%02d:%02d", minutes, seconds) : String(format: "%02d %02d", minutes, seconds)
        } else {
            self.timeLabel.text = String(format: "%02d", seconds)
        }
    }
    
    func gameOver() {
        self.removeAction(forKey: "countSeconds")
        self.setTimeLabel(alwaysDisplayColon: true)
        if isWarheadRaidOn { self.warheadRaidTimer.invalidate() }
        if isBomberRaidOn { self.bomberRaidTimer.invalidate() }
        if isTzarRaidOn { self.tzarRaidTimer.invalidate() }
        generateGameOverLabel()
        generateRetryButtonLabel()
    }
    
    func setDifficulty(time: Int) {
        if isGameOver { return }
        
        let level = time / 30 + 1
        
        self.generateDifficultyLabel(text: "\(level)", fontColor: .red)
        
        if(level <= 10) {
            self.isWarheadRaidOn = true
            self.warheadPerRaid += 1
            self.warheadRaidInterval -= 0.5
        }
        
        if(level >= 5 && level <= 15) {
            self.isTzarRaidOn = true
            self.tzarRaidInterval -= 0.527
        }
        
        if(level >= 8 && level <= 20) {
            self.isBomberRaidOn = true
            self.bomberRaidInterval -= 1.233
        }
        
        if(level == 3) {
            self.enemyWarheadBlastRangeCandidates.append(50)
            self.enemyWarheadVelocityCandidates.append(60)
        }
        
        if(level == 5) {
            self.enemyWarheadBlastRangeCandidates.append(55)
            self.enemyWarheadVelocityCandidates.append(70)
        }
        
        if(level == 10) {
            self.enemyWarheadBlastRangeCandidates.append(60)
            self.enemyWarheadVelocityCandidates.append(80)
        }
        
        if(level == 15) {
            self.enemyWarheadBlastRangeCandidates.append(65)
            self.enemyWarheadVelocityCandidates.append(90)
        }
    }
    
    // MARK: - Generating sprites
    func dropRandomItem(probability: Double, position: CGPoint) {
        if gacha(probability: probability) {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.globalExplosionDuration) {
                self.generateRandomItem(position: position)
            }
        }
    }
    
    func generateRandomItem(position: CGPoint = CGPoint(x: CGFloat.random(in: 100...400), y: CGFloat.random(in: 100...500))) {
        let randomPick = Int.random(in: 1...7)
        var randomItem: Item?
        switch randomPick {
        case 1:
            randomItem = AmmunitionItem(position: position, gameScene: self)
        case 2:
            randomItem = BlastItem(position: position, gameScene: self)
        case 3:
            randomItem = DurationItem(position: position, gameScene: self)
        case 4:
            randomItem = ReloadItem(position: position, gameScene: self)
        case 5:
            randomItem = VelocityItem(position: position, gameScene: self)
        case 6:
            randomItem = SiloItem(position: position, gameScene: self)
        case 7:
            randomItem = CityItem(position: position, gameScene: self)
        default:
            print("missing item pick")
        }
        guard let pickedItem = randomItem else { return }
        self.addChild(pickedItem)
    }
    
    func generateGameOverLabel() {
        let gameOverLabel = SKLabelNode(fontNamed: "PressStart2P")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverLabel.zPosition = 100
        let wait = SKAction.wait(forDuration: 2)
        let show = SKAction.run { self.addChild(gameOverLabel) }
        self.run(SKAction.sequence([wait, show]))
    }
    
    func generateDifficultyLabel(text: String, fontColor: UIColor) {
        let difficultyLabel = SKLabelNode(fontNamed: "PressStart2P")
        difficultyLabel.text = text
        difficultyLabel.fontSize = 40
        difficultyLabel.fontColor = fontColor
        difficultyLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        difficultyLabel.zPosition = 100
        if !isGameOver {
            self.addChild(difficultyLabel)
            let wait = SKAction.wait(forDuration: 3)
            let delete = SKAction.run { difficultyLabel.removeFromParent() }
            let item = SKAction.run { self.generateRandomItem() }
            self.run(SKAction.sequence([wait, delete, item]))
        }
    }
    
    func generateRetryButtonLabel() {
        let retryLabel = SKLabelNode(fontNamed: "PressStart2P")
        retryLabel.text = "Tap to try again"
        retryLabel.name = "retryLabel"
        retryLabel.fontSize = 20
        retryLabel.fontColor = .yellow
        retryLabel.position = CGPoint(x: frame.midX, y: frame.midY - 30)
        retryLabel.zPosition = 100
        let wait = SKAction.wait(forDuration: 4)
        let add = SKAction.run {
            self.addChild(retryLabel)
            self.isGameOver = true
        }
        self.run(SKAction.sequence([wait, add]))
    }
    
    func generateComboLabel(combo: Int, position: CGPoint, range: Int) {
        if combo != 0 {
            let comboLabel = SKLabelNode(fontNamed: "PressStart2P")
            comboLabel.text = combo == 1 ? "\(combo) COMBO" : "\(combo) COMBOS"
            comboLabel.fontSize = 15
            comboLabel.fontColor = combo < 5 ? SKColor.yellow : SKColor.red
            comboLabel.position = CGPoint(x: position.x, y: position.y + CGFloat(range / 2))
            comboLabel.zPosition = 1
            self.addChild(comboLabel)
            
            let wait = SKAction.wait(forDuration: 2)
            let remove = SKAction.run { comboLabel.removeFromParent() }
            self.run(SKAction.sequence([wait, remove]))
        }
    }
    
    func generateItemLabel(upgradable: Bool, itemName: String, color: SKColor, position: CGPoint, range: Int) {
        let comboLabel = SKLabelNode(fontNamed: "PressStart2P")
        comboLabel.text = "+\(upgradable ? itemName : String(GameScene.itemScore))"
        comboLabel.fontSize = 15
        comboLabel.fontColor = color
        comboLabel.position = CGPoint(x: position.x, y: position.y + CGFloat(range / 2))
        comboLabel.zPosition = 1
        self.addChild(comboLabel)
        
        let wait = SKAction.wait(forDuration: 2)
        let remove = SKAction.run { comboLabel.removeFromParent() }
        self.run(SKAction.sequence([wait, remove]))
    }
    
    @objc func generateEnemyWarhead() {
        for _ in 1...warheadPerRaid {
            guard let randomTargetLocation = self.randomTargetLocation else {
                print("no targets are available")
                return
            }
            
            let to = self.calculateActualCoordinateOfLocation(location: randomTargetLocation, usePreciseLocation: false)
            let fromX = Int.random(in: 1...500)
            let from = CGPoint(x: fromX, y: 600)
            
            let distance = getDistance(from: from, to: to)
            let velocity = CGFloat(self.enemyWarheadVelocityCandidates.randomElement()!)
            let blastRange =  self.enemyWarheadBlastRangeCandidates.randomElement()!
            let enemyWarhead = EnemyWarhead(position: from, distance: distance, velocity: velocity, targetCoordinate: to, blastRange: blastRange, gameScene: self)
            addChild(enemyWarhead)
        }
    }
    
    @objc func generateEnemyBomber() {
        for _ in 1...bomberPerRaid {
            let fromY = Int.random(in: 200...450)
            let flightTime = Double.random(in: 2...5)
            let bombingDuration = Double.random(in: 0.2...0.8)
            let blastRange =  self.enemyWarheadBlastRangeCandidates.randomElement()!
            let bomber = Bomber(yPosition: CGFloat(fromY), fromRight: Bool.random(), flightTime: flightTime, bombingDuration: bombingDuration, blastRange: blastRange, gameScene: self)
            addChild(bomber)
        }
    }
    
    @objc func generateEnemyTzar() {
        for _ in 1...tzarPerRaid {
            guard let randomTargetLocation = self.randomTargetLocation else {
                print("no targets are available")
                return
            }
            
            let to = self.calculateActualCoordinateOfLocation(location: randomTargetLocation, usePreciseLocation: false)
            let fromX = Int.random(in: 1...500)
            let from = CGPoint(x: fromX, y: 600)
            
            let distance = getDistance(from: from, to: to)
            let velocity = CGFloat(self.enemyWarheadVelocityCandidates.randomElement()!)
            let blastRange = 300
            let enemyWarhead = EnemyWarhead(position: from, distance: distance, velocity: velocity, targetCoordinate: to, blastRange: blastRange, gameScene: self)
            addChild(enemyWarhead)
        }
    }
    
    func generateSilos() {
        for location in siloLocation {
            let position = self.calculateActualCoordinateOfLocation(location: location)
            let silo = Silo(position: position, gameScene: self)
            silos.append(silo)
            
            addChild(silo)
        }
    }
    
    func generateCities() {
        for location in cityLocation {
            let position = self.calculateActualCoordinateOfLocation(location: location)
            let city = City(position: position)
            cities.append(city)
            
            addChild(city)
        }
    }
}
