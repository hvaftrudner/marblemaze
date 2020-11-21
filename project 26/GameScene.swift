//
//  GameScene.swift
//  project 26
//
//  Created by Kristoffer Eriksson on 2020-11-19.
//
import CoreMotion
import SpriteKit

enum collisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
    case teleport = 32
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    
    var motionManager: CMMotionManager?
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet{
            scoreLabel.text = "score: \(score)"
        }
    }
    var isGameOver = false
    
    var levelNum = 1
    
    override func didMove(to view: SKView) {
        
        loadLevel()
        //maps did register an empty line in the .txt file, had to remove the reverse and add new
        //spawnpoint to player
        createPlayer(at: CGPoint(x: 96, y: 96))
        addBasicProperties()
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
    }
    
    func addBasicProperties(){
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
    }
    
    func loadLevel(){
        removeAllChildren()
        
        guard let lvlUrl = Bundle.main.url(forResource: "level\(String(levelNum))", withExtension: "txt") else {fatalError("could not find level\(String(levelNum)).txt in the app bundle")}
        guard let lvlString = try? String(contentsOf: lvlUrl) else {fatalError("could not load level1.txt from the app bundle")}
        
        let lines = lvlString.components(separatedBy: "\n")
        
        for (row, line) in lines.enumerated(){
            for (column, letter) in line.enumerated().reversed(){
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                
                addBox(letter: letter, to: position)
            }
        }
    }
    func addBox(letter: Character, to position: CGPoint){
        if letter == "x"{
            addWall(to: position)
            
        } else if letter == "v"{
            addVortex(to: position)
            
        } else if letter == "s"{
            addStar(to: position)
            
        } else if letter == "f"{
            addFinish(to: position)
            
        } else if letter == "t"{
            addTeleport(to: position)
        } else if letter == " "{
            //empty space do nothing
        } else {
            fatalError("unknown level letter \(letter)")
        }
    }
    func addTeleport(to position: CGPoint){
        let node = SKSpriteNode(imageNamed: "vortex")
        node.position = position
        node.name = "teleport"
        //changing color of existing sprite
        node.color = UIColor.cyan
        node.colorBlendFactor = 0.8
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: -.pi, duration: 1)))
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = collisionTypes.teleport.rawValue
        node.physicsBody?.contactTestBitMask = collisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.isDynamic = false
        
        addChild(node)
    }
    func addWall(to position: CGPoint){
        let node = SKSpriteNode(imageNamed: "block")
        node.position = position
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = collisionTypes.wall.rawValue
        node.physicsBody?.isDynamic = false
        
        addChild(node)
    }
    func addVortex(to position: CGPoint){
        let node = SKSpriteNode(imageNamed: "vortex")
        node.name = "vortex"
        node.position = position
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = collisionTypes.vortex.rawValue
        //notify us if player collides
        node.physicsBody?.contactTestBitMask = collisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        
        addChild(node)
    }
    func addStar(to position: CGPoint){
        let node = SKSpriteNode(imageNamed: "star")
        node.name = "star"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = collisionTypes.star.rawValue
        node.physicsBody?.contactTestBitMask = collisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    func addFinish(to position: CGPoint){
        let node = SKSpriteNode(imageNamed: "finish")
        node.name = "finish"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = collisionTypes.finish.rawValue
        node.physicsBody?.contactTestBitMask = collisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    func createPlayer(at position: CGPoint){
        player = SKSpriteNode(imageNamed: "player")
        player.position = position
        player.zPosition = 1
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = collisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = collisionTypes.star.rawValue | collisionTypes.vortex.rawValue | collisionTypes.finish.rawValue | collisionTypes.teleport.rawValue
        player.physicsBody?.collisionBitMask = collisionTypes.wall.rawValue
        
        addChild(player)
        
    }
    //simulated movement
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        guard isGameOver == false else {return}
        
        #if targetEnvironment(simulator)
        if let lastTouchPosition = lastTouchPosition {
            let diff = CGPoint(x: lastTouchPosition.x - player.position.x, y: lastTouchPosition.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
        #else
        if let accelorometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelorometerData.acceleration.y * -50, dy: accelorometerData.acceleration.x * 50)
        }
        #endif
        
    }
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else {return}
        guard let nodeB = contact.bodyB.node else {return}
        
        if nodeA == player {
            playerCollided(node: nodeB)
        } else if nodeB == player {
            playerCollided(node: nodeA)
        }
    }
    func playerCollided(node: SKNode){
        if node.name == "vortex"{
            player.physicsBody?.isDynamic = false
            isGameOver = true
            score -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            
            let sequence = SKAction.sequence([move, scale, remove])
            player.run(sequence) {
                [weak self] in
                self?.createPlayer(at: CGPoint(x: 96, y: 96))
                self?.isGameOver = false
            }
            
        } else if node.name == "star"{
            node.removeFromParent()
            score += 1
            
        } else if node.name == "finish"{
            //exits after last level. add higher num to enable more levels
            
            //refractor to own startgame / end game func
            if levelNum < 4 {
                levelNum += 1
                
                player.removeFromParent()
                player.removeAllActions()
                loadLevel()
                createPlayer(at: CGPoint(x: 96, y: 96))
                addBasicProperties()
            } else {
                player.physicsBody?.isDynamic = false
                removeAllChildren()
                
                let gameOverLabel = SKLabelNode(fontNamed: "chalkduster")
                gameOverLabel.text = "You finished the game!"
                gameOverLabel.fontSize = 60
                gameOverLabel.zPosition = 5
                gameOverLabel.position = CGPoint(x: 512, y: 384)
                addChild(gameOverLabel)
                
                let gameOverScore = SKLabelNode(fontNamed: "chalkduster")
                gameOverScore.text = "end score : \(score)"
                gameOverScore.fontSize = 48
                gameOverScore.zPosition = 5
                gameOverScore.position = CGPoint(x: 512, y: 280)
                addChild(gameOverScore)
            }
        } else if node.name == "teleport"{
            var teleportNodes = [SKNode]()
            
            for node in children {
                if node.name == "teleport"{
                    teleportNodes.append(node)
                }
            }
            print(teleportNodes.count)
            
            //ensures that there are more teleports
            if teleportNodes.count > 1 {
                if teleportNodes[0] == node {
                    print(teleportNodes[0].position)
                    let move = SKAction.move(to: node.position, duration: 0.25)
                    let scale = SKAction.scale(to: 0.0001, duration: 0.25)
                    let remove = SKAction.removeFromParent()
                    let sequence = SKAction.sequence([move, scale, remove])
                    player.run(sequence) {
                        [weak self] in
                        self?.createPlayer(at: teleportNodes[1].position)
                        self?.isGameOver = false
                    }
                    
                    removeChildren(in: teleportNodes)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        self.addTeleport(to: teleportNodes[0].position)
                        self.addTeleport(to: teleportNodes[1].position)
                    }
                    
                } else if teleportNodes[1] == node{
                    let move = SKAction.move(to: node.position, duration: 0.25)
                    let scale = SKAction.scale(to: 0.0001, duration: 0.25)
                    let remove = SKAction.removeFromParent()
                    let sequence = SKAction.sequence([move, scale, remove])
                    player.run(sequence) {
                        [weak self] in
                        self?.createPlayer(at: teleportNodes[0].position)
                        self?.isGameOver = false
                    }
                    removeChildren(in: teleportNodes)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        self.addTeleport(to: teleportNodes[0].position)
                        self.addTeleport(to: teleportNodes[1].position)
                    }
                }
            }
        }
    }
}
