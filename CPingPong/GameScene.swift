//
//  GameScene.swift
//  Ping-Pong
//
//  Created by Prashuk Ajmera on 5/21/19.
//  Copyright © 2019 Prashuk Ajmera. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Constants
    let TABLE_HEIGHT_WIDTH_RATIO : Double = 1.79672131148
    let SHADOW_DISTANCE : Double = 200
    let TABLE_BALL_RATIO : Double = 15
    
    var MAX_PAD_VELOCITY : Double {
        return 2 * Double(self.size.height)
    }
    var table_width : Double {
        print ("Width: \(self.size.width) Height: \(self.size.height)")
        if self.size.width * 16/9 <= self.size.height {
            return self.size.width * 0.7
        } else {
            return self.size.height * 0.7 / TABLE_HEIGHT_WIDTH_RATIO
        }
    }
    
    var lastUpdateTime : TimeInterval?
    var dt : TimeInterval = 0
    
    
    // elements
    var table : SKSpriteNode?
    var ball : SKSpriteNode?
    var shadow : SKSpriteNode?
    var p1 : SKSpriteNode?
    var p2 : SKSpriteNode?
    
    // movements
    var p1PrevLocation : CGPoint? // prev locations needed for velocity calculation
    var p2PrevLocation : CGPoint?
    var p1_X_Velocity : Double {
        return (p1!.position.x - p1PrevLocation!.x)/dt
    }
    var p1_Y_Velocity : Double {
        return min((p1!.position.y - p1PrevLocation!.y)/dt *
                   abs((table?.size.height)! / 2 / p1!.position.y), MAX_PAD_VELOCITY)
    }
    var p2_X_Velocity : Double {
        return (p2!.position.x - p2PrevLocation!.x)/dt
    }
    var p2_Y_Velocity : Double {
        return max((p2!.position.y - p2PrevLocation!.y)/dt *
                   abs((table?.size.height)! / 2 / p2!.position.y), -MAX_PAD_VELOCITY)
    }
    var ball_X_Velocity : Double = 0
    var ball_Y_Velocity : Double = 0
    var ball_spin : Double = 0
    let drag_coefficient : Double = 0.5
    var ball_height : Double = 0 { // height off the table
        didSet {
            if ball_height >= 0 {
                shadow?.isHidden = false
                shadow?.position.x = ball!.position.x + CGFloat(ball_height * SHADOW_DISTANCE)
            } else {
                shadow?.isHidden = true
            }
            ball?.size = CGSize(width: max(table_width / TABLE_BALL_RATIO + ball_height * 10, 0), height: max(table_width / TABLE_BALL_RATIO + ball_height * 10, 0))
        }
    }
    let gravity : Double = -3
    var ball_Z_Velocity : Double = 0 // vertical velocity
    
    // game play status
    var game_started : Bool = false
    var p1_hit : Bool = true
    var serving : Bool = true
    var passedTheNet : Bool = true {
        didSet {
            if passedTheNet {
                bounced = false
            }
        }
    }
    var bounced : Bool = false
    var smashed : Bool = false
    var wait_for_reset : Bool = false // when waiting for reset, do not check for rule violation
    
    // text indicators and scoring
    var score : [Int]? {
        didSet {
            topLbl?.text = "\(score![1])"
            bottomLbl?.text = "\(score![0])"
        }
    }
    var topLbl : SKLabelNode?
    var bottomLbl : SKLabelNode?
    var message : SKLabelNode?
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector.zero
        
        table = SKSpriteNode(imageNamed: "table um")
        table?.size = CGSize(width: table_width, height: table_width * table!.size.height / table!.size.width)
        table?.zPosition = 0.1
        table?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        table?.position = CGPoint.zero
        self.addChild(table!)
        let table_shadow = SKShapeNode(rect: CGRect(origin: CGPoint(x: 15 - table_width/2, y: -15 - table!.size.height/2), size: table!.size), cornerRadius: 5)
        table_shadow.zPosition = -1
        table_shadow.fillColor = .black
        table_shadow.strokeColor = .clear
        table_shadow.alpha = 0.5
        table?.addChild(table_shadow)
        
        ball = SKSpriteNode(imageNamed: "ball")
        ball?.size = CGSize(width: table_width / TABLE_BALL_RATIO, height: table_width / TABLE_BALL_RATIO)
        ball?.zPosition = 20
        ball?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        ball?.name = "ball"
        ball?.physicsBody = SKPhysicsBody(rectangleOf: ball!.size)
        ball?.physicsBody?.contactTestBitMask = 1
        ball?.physicsBody?.collisionBitMask = 0
        self.addChild(ball!)
        
        shadow = SKSpriteNode(color: .clear, size: ball!.size)
        let circle = SKShapeNode(circleOfRadius: ball!.size.width/2)
        circle.fillColor = .black
        circle.strokeColor = .clear
        circle.alpha = 0.8
        shadow?.zPosition = 19
        shadow?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        shadow?.addChild(circle)
        self.addChild(shadow!)
        
        p1 = SKSpriteNode(imageNamed: "pad1 um")
        p1?.size = CGSize(width: ball!.size.width * 3, height: ball!.size.width * 3 / p1!.size.width * p1!.size.height)
        p1?.zPosition = 10
        p1?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        p1?.name = "p1"
        p1?.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: p1!.size.width * 0.8, height: ball!.size.width))
        p1?.physicsBody?.contactTestBitMask = 1
        p1?.physicsBody?.isDynamic = false
        self.addChild(p1!)
        
        p2 = SKSpriteNode(imageNamed: "pad2 um")
        p2?.size = CGSize(width: ball!.size.width * 3, height: ball!.size.width * 3 / p2!.size.width * p2!.size.height)
        p2?.zPosition = 10
        p2?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        p2?.name = "p2"
        p2?.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: p2!.size.width * 0.8, height: ball!.size.width))
        p2?.physicsBody?.contactTestBitMask = 1
        p2?.physicsBody?.isDynamic = false
        self.addChild(p2!)
        p2PrevLocation = p2?.position
        
        let scoreBoard = SKShapeNode(rect: CGRect(origin: CGPoint(x: self.frame.maxX - 10 - table_width / 7, y: -table!.size.height / 3), size: CGSize(width: table_width / 7, height: 2 * table!.size.height / 3)), cornerRadius: 20)
        scoreBoard.zPosition = 0
        scoreBoard.strokeColor = .clear
        scoreBoard.fillColor = UIColor(red: 101.0/255, green: 23.0/255, blue: 201.0/255, alpha: 1)
        self.addChild(scoreBoard)
        let minipad1_icon = SKSpriteNode(imageNamed: "mini pad 1 um")
        minipad1_icon.zPosition = 1
        minipad1_icon.position = CGPoint(x: scoreBoard.frame.midX, y: scoreBoard.frame.minY + 30)
        minipad1_icon.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        minipad1_icon.zRotation = -.pi / 2
        scoreBoard.addChild(minipad1_icon)
        let minipad2_icon = SKSpriteNode(imageNamed: "mini pad 2 um")
        minipad2_icon.zPosition = 1
        minipad2_icon.position = CGPoint(x: scoreBoard.frame.midX, y: scoreBoard.frame.maxY - 30)
        minipad2_icon.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        minipad2_icon.zRotation = -.pi / 6
        scoreBoard.addChild(minipad2_icon)
        
        topLbl = SKLabelNode()
        topLbl?.fontName = "HelveticaNeue-Bold"
        topLbl?.fontColor = .white
        topLbl?.fontSize = 30
        topLbl?.position = CGPoint(x: scoreBoard.frame.midX - 12, y: self.frame.midY + table!.size.height / 5)
        topLbl?.zRotation = -.pi / 2
        topLbl?.zPosition = 100
        self.addChild(topLbl!)
        
        bottomLbl = SKLabelNode()
        bottomLbl?.fontName = "HelveticaNeue-Bold"
        bottomLbl?.fontColor = .white
        bottomLbl?.fontSize = 30
        bottomLbl?.position = CGPoint(x: scoreBoard.frame.midX - 12, y: self.frame.midY - table!.size.height / 5)
        bottomLbl?.zRotation = -.pi / 2
        bottomLbl?.zPosition = 100
        self.addChild(bottomLbl!)
        
        message = SKLabelNode()
        message?.fontName = "HelveticaNeue-Bold"
        message?.fontColor = UIColor(red: 101.0/255, green: 23.0/255, blue: 201.0/255, alpha: 1)
        message?.fontSize = 40
        message?.position = CGPoint(x: self.frame.minX + 45, y: self.frame.midY)
        message?.zRotation = .pi / 2
        message?.zPosition = 100
        self.addChild(message!)
        
        
        startGame()
    }

    func startGame() {

        fullReset()
        
    }
    
    func addScore(stroker is_p1 : Bool) {
        if is_p1 {
            score![1] += 1
        } else {
            score![0] += 1
        }
    }
    
    
    // Contact Detection
    func didBegin(_ contact: SKPhysicsContact) {
        
        if wait_for_reset { // no update
            return
        }
        
        message?.text = ""
        
        // check for passing the net because one can only hit the ball once
        if passedTheNet {
            
            var pad1 : Bool!
            if contact.bodyA.node?.name == "ball" {
                pad1 = contact.bodyB.node?.name == "p1"
            }
            else if contact.bodyB.node?.name == "ball" {
                pad1 = contact.bodyA.node?.name == "p1"
            }
            
            // takes care of the case ball spawns on a pad
            if !game_started {
                if (pad1) ? p1_Y_Velocity > 0 : p2_Y_Velocity < 0 {
                    game_started = true // start the game if moving pad touches the ball
                } else {
                    return
                }
            }
            
            p1_hit = pad1
            
            // if pad touches the ball before bounce (except for serve)
            if !bounced && !serving {
                if ballOutofBound() { // if the ball is already out, it is out
                    message?.text = "OUT"
                    p1_hit = !p1_hit // receiver score
                } else {
                    message?.text = "Volleying"
                }
                round_over()
            }
            
            // Rebounce
            ball_Y_Velocity = -ball_Y_Velocity * 0.6
            ball_X_Velocity = -ball_X_Velocity * 0.6
            
            // Forward Velocity
            ball_Y_Velocity += ((pad1) ? p1_Y_Velocity : p2_Y_Velocity) / 3
            
            if smashed {
                ball_X_Velocity += Double.random(in: -300...300)
                smashed = false
            }
            // if the ball is high enough, the stroke is considered a Smash
            // --a stroker too fast to react
            if ball_height > 0.4 {
                ball_Y_Velocity *= ball_height * 2 + 1
                if abs(ball_Y_Velocity) > 1400 {
                    message?.text = "SMASH!!!"
                    smashed = true
                }
            }
            
            // if the X Velocity is high enough, it will induce a spin to the ball
            let side_spin = (pad1) ? abs(p1_X_Velocity) * 2 > abs(p1_Y_Velocity) : abs(p2_X_Velocity) * 2 > abs(p2_Y_Velocity)
            
            print(side_spin)
            print("x:\((pad1) ? p1_X_Velocity: p2_X_Velocity), y:\((pad1) ? p1_Y_Velocity : p2_Y_Velocity)")
            
            if side_spin {
                let spin = ((pad1) ? p1_X_Velocity : -p2_X_Velocity) / 4
                ball_spin += spin
                ball_X_Velocity += (ball_Y_Velocity > 0) ? (ball_spin / 2) : (-ball_spin / 2)
                ball_X_Velocity += ((pad1) ? p1_X_Velocity : p2_X_Velocity) / 1024
            } else {
                ball_X_Velocity += ((pad1) ? p1_X_Velocity : p2_X_Velocity) / 3
                ball_X_Velocity += (ball_Y_Velocity > 0) ? (ball_spin) : (-ball_spin)
                ball_spin /= 4
            }
            
            // calculate the angle, represented by vertical velocity, required to get the ball
            // to a desired location
            // this is done automatically based on the ball's velocity
            if serving {
                ball_Z_Velocity = -0.8
                serving = false
                passedTheNet = false
            } else {
                var target_distance = ball_Y_Velocity * table!.size.height * 0.8 / (MAX_PAD_VELOCITY / 3)
                if abs(target_distance) > table!.size.height/2 {
                    let direction = ball_Y_Velocity > 0 ? 1.0 : -1.0
                    target_distance = direction * (table!.size.height/2 - 50 + Double.random(in: -80..<80))
                }
                let travel_distance = target_distance - ball!.position.y
                ball_Z_Velocity = -ball_height*ball_Y_Velocity/travel_distance - 0.5*gravity*travel_distance/ball_Y_Velocity
                if ball_Z_Velocity > 2 {
                    ball_Z_Velocity = 2
                }
            }
            
            passedTheNet = false
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if location.y < -20 {
                p1?.run(SKAction.move(to: location, duration: 0))
                p1PrevLocation = p1!.position
//                if serving && ball!.position.y < 0 {
//                    ball?.run(SKAction.moveTo(x: p1!.position.x, duration: 0))
//                    ball_height = ball_height * 1
//                }
            }
            if location.y > 20 {
                p2?.run(SKAction.move(to: location, duration: 0))
                p2PrevLocation = p2!.position
//                if serving && ball!.position.y > 0 {
//                    ball?.run(SKAction.moveTo(x: p2!.position.x, duration: 0))
//                    ball_height = ball_height * 1
//                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if location.y < -20 {
                p1?.run(SKAction.move(to: location, duration: 0))
            }
            if location.y > 20 {
                p2?.run(SKAction.move(to: location, duration: 0))
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        defer {
            lastUpdateTime = currentTime
            p1PrevLocation = p1?.position
            p2PrevLocation = p2?.position
        }
        guard lastUpdateTime != nil else {
            return
        }
        if let lastTime = lastUpdateTime  {
            dt = currentTime - lastTime
            dt = dt / 2
        }
        
        if game_started {
            
            // trace of the ball
            let trace = SKShapeNode(circleOfRadius: ball!.size.width / 2)
            trace.lineWidth = 2.0
            trace.fillColor = .white
            if abs(ball_X_Velocity) + abs(ball_Y_Velocity) > 1100 {
                trace.strokeColor = .cyan
            } else if abs(ball_X_Velocity) + abs(ball_Y_Velocity) > 800 {
                trace.strokeColor = .orange
            } else {
                trace.strokeColor = .white
            }
            trace.zPosition = 18
            trace.position = ball!.position
            self.addChild(trace)
            trace.run(SKAction.scale(to: 0, duration: 1))
            trace.run(SKAction.fadeOut(withDuration: 1), completion: {
                trace.removeFromParent()
            })
            
            // reduction on velocity and spin due to air resistance
            let prevY = ball?.position.y
            ball_Y_Velocity -= ball_Y_Velocity * drag_coefficient * dt
            ball?.position.y += ball_Y_Velocity * dt
            ball_X_Velocity -= ball_X_Velocity * drag_coefficient * dt
            ball?.position.x += ball_X_Velocity * dt
            ball_spin -= ball_spin * drag_coefficient * dt
            
            // change of direction due to spin
            let ball_V_sqrd = ball_X_Velocity * ball_X_Velocity + ball_Y_Velocity * ball_Y_Velocity
            ball_X_Velocity += ball_Y_Velocity > 0 ? -ball_spin * dt : ball_spin * dt
            let new_Y_V_due_to_spin = sqrt(abs(ball_V_sqrd - ball_X_Velocity * ball_X_Velocity))
            ball_Y_Velocity = (ball_Y_Velocity > 0) ? new_Y_V_due_to_spin : -new_Y_V_due_to_spin
            
            // the middle of the table has y-coordinate of 0
            if Double(prevY!) * Double((ball?.position.y)!) <= 0 {
                passedTheNet = true
            }
            
            // Vertical update
            if !ballOutofBound() {
                if ball_height > 0 {
                    ball_Z_Velocity += gravity * dt
                    ball_height += ball_Z_Velocity * dt
                } else if ball_height > -0.1 { // Deal with ball hitting table
                    if bounced {
                        if !wait_for_reset {
                            if passedTheNet {
                                p1_hit = !p1_hit
                            }
                            message?.text = "Double Bounce"
                            round_over()
                        }
                    } else {
                        bounced = true
                    }
                    
                    // reflect off the table top
                    ball_Z_Velocity = -ball_Z_Velocity * 0.9
                    ball_height = 0.01
                    // change of direction due to spin
                    ball_X_Velocity -= (ball_Y_Velocity > 0 ? 1 : -1) * ball_spin * 0.3
                    ball_spin *= 0.85
                    
                    // a marker on the table to indicate bounce
                    let dot = SKShapeNode(circleOfRadius: ball!.size.width / 2)
                    dot.fillColor = .red
                    dot.strokeColor = .red
                    dot.alpha = 0.5
                    dot.zPosition = 100
                    dot.position = ball!.position
                    self.addChild(dot)
                    dot.run(SKAction.fadeOut(withDuration: 1), completion: {
                        dot.removeFromParent()
                    })
                }
            } else {
                if (ball_height < -1 || (ball_height < 0 && ballOutOfScreen())) && !wait_for_reset {
                    if !bounced || !passedTheNet {
                        message?.text = "OUT"
                    } else {
                        p1_hit = !p1_hit
                        message?.text = "Score"
                    }
                    round_over()
                }
                ball_Z_Velocity += gravity * dt
                ball_height += ball_Z_Velocity * dt
            }
            
            // Check ball height when crossing the net
            if (prevY! * ball!.position.y <= 0 && ball_height < 0.1) && !ballOutofBound() && !wait_for_reset{
                if Int.random(in: 1...20) == 1 {
                    // the case when scratching the net but still passes
                    // very powerful in real life "lucky ball"
                    ball_Y_Velocity = ball_Y_Velocity * 0.1
                } else {
                    message?.text = "NET"
                    ball_Y_Velocity = -ball_Y_Velocity * 0.1
                    round_over()
                }
            }
            
            
        }
        
        shadow?.position.y = ball!.position.y
        
    }
    
    func ballOutOfScreen () -> Bool {
        return (ball?.position.x)! < -self.size.width/2 || (ball?.position.x)! > self.size.width/2 ||
        (ball?.position.y)! < -self.size.height/2 || (ball?.position.y)! > self.size.height/2
    }
    
    func ballOutofBound () -> Bool {
        return (ball?.position.x)! < -table_width/2 || (ball?.position.x)! > table_width/2 ||
        (ball?.position.y)! < -table!.size.height/2 || (ball?.position.y)! > table!.size.height/2
    }
    
    func round_over () {
        wait_for_reset = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            addScore(stroker: p1_hit)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
            if !((score![0] >= 11 || score![1] >= 11) && abs(score![0]-score![1]) > 1) {
                reset()
            } else {
                message?.text = score![0] > score![1] ? "<- Winner -<" : ">- Winner ->"
            }
        }
    }
    
    // reset the ball
    func reset () {
        print("reset")
        // reset ball position
        ball_X_Velocity = 0
        ball_Y_Velocity = 0
        ball_Z_Velocity = 0
        ball_height = 0.1
        ball_spin = 0
        ball?.position = CGPoint(x: (table?.position.x)!, y: ((Int.random(in: 0...1) == 0) ? -table!.size.height / 2.5 : table!.size.height / 2.5))
        shadow?.position = ball!.position
        
        // reset message
        message?.text = ""
        
        // Booleans
        game_started = false
        serving = true
        passedTheNet = true
        bounced = false
        wait_for_reset = false
    }
    
    // reset the game
    func fullReset() {
        reset()
        message?.text = "Hit the ball to start"
        score = [0,0]
        
        p1?.position = CGPoint(x: (table?.position.x)!, y: -table!.size.height/2 - 25)
        p1PrevLocation = p1?.position
        p2?.position = CGPoint(x: (table?.position.x)!, y: table!.size.height/2 + 25)
        p2PrevLocation = p2?.position
        
    }
    
}
