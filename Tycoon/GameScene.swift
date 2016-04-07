//
//  GameScene.swift
//  Tycoon
//
//  Created by Nico Hämäläinen on 27/03/16.
//  Copyright (c) 2016 sizeof.io. All rights reserved.
//

import SpriteKit

enum ProgrammerType: Int {
  case Newbie
  case Professional
  case Expert
  case Ninja
  
  static let allValues = [Newbie, Professional, Expert, Ninja]
}

extension ProgrammerType {
  var name: String {
    switch self {
    case .Newbie:
      return "Newbie"
    case .Professional:
      return "\"Pro\""
    case .Expert:
      return "Expert"
    case .Ninja:
      return "Ninja"
    }
  }
  
  var baseCost: Double {
    switch self {
    case .Newbie:
      return 10
    case .Professional:
      return 25
    case .Expert:
      return 150
    case .Ninja:
      return 1000
    }
  }
  
  var production: Double {
    switch self {
    case .Newbie:
      return 1
    case .Professional:
      return 5
    case .Expert:
      return 10
    case .Ninja:
      return 50
    }
  }
  
  var costIncreaseRatio: Double {
    return 1.1
  }
  
  func costForCount(count: Int) -> Int {
    if count == 1 { return Int(baseCost); }
    return Int(baseCost * pow(costIncreaseRatio, Double(count)))
  }
  
  func productionForDeltaTime(delta time: CFTimeInterval) -> Double {
    return production * (1 / ceil(1.0 / time))
  }
}

/// Represents a single company that's gaining money during the game
struct Company {
  /// The name of the company
  var name: String
  /// The `Programmer`s hired to work in this company
  var programmers: [ProgrammerType: Int]
  /// The amount of money this company has
  var money: Double
  
  /// Create a new company
  /// - parameter name: The name of the company
  /// - returns: The newly created company
  init(name: String) {
    self.name = name
    self.money = 0
    self.programmers = [
      ProgrammerType.Newbie: 0,
      ProgrammerType.Professional: 0,
      ProgrammerType.Expert: 0,
      ProgrammerType.Ninja: 0,
    ]
  }
}

extension Company {
  func ableToHire(type type: ProgrammerType, withCount count: Int) -> Bool {
    return money >= Double(type.costForCount(count))
  }
  
  mutating func hire(type type: ProgrammerType) {
    money -= Double(type.costForCount(programmers[type]!))
    programmers[type]! += 1
  }
  
  mutating func tick(deltaTime time: CFTimeInterval) {
    programmers.forEach { (programmer, count) in
      for _ in 0..<count {
        let production = programmer.productionForDeltaTime(delta: time)
        self.money += production
      }
    }
  }
  
  mutating func returnBottles(amount amount: Double) {
    money += amount
  }
  
  func incomePerSecond() -> Double {
    return programmers.reduce(0, combine: { $0 + ($1.0.production * Double($1.1)) })
  }
}

class GameScene: SKScene {
  var lastUpdateTime: CFTimeInterval = 0
  var company = Company(name: "Maratron Inc.")
  
  var companyLabel = SKLabelNode(fontNamed: "OperatorMono-Book")
  var moneyLabel = SKLabelNode(fontNamed: "OperatorMono-Book")
  var programmerNodes = [ProgrammerType: SKShapeNode]()
  var manualNode: SKShapeNode = SKShapeNode(rectOfSize: CGSize(width: 320, height: 64), cornerRadius: 12.0)
  
  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    
    companyLabel.fontSize = 16.0
    companyLabel.position.x = 20.0
    companyLabel.position.y = size.height - companyLabel.frame.height - 40.0
    companyLabel.horizontalAlignmentMode = .Left
    companyLabel.verticalAlignmentMode = .Center
    companyLabel.text = company.name
    addChild(companyLabel)
    
    moneyLabel.verticalAlignmentMode = .Center
    moneyLabel.horizontalAlignmentMode = .Left
    moneyLabel.text = "Money: €0 - (€0 / second)"
    moneyLabel.fontSize = 16.0
    addChild(moneyLabel)
    
    manualNode.strokeColor = .clearColor()
    manualNode.position = CGPoint(x: 20.0 + 160, y: 54)
    manualNode.fillColor = .whiteColor()
    
    let manualTextNode = SKLabelNode(fontNamed: "OperatorMono-Bold")
    manualTextNode.fontColor = SKColor.blueColor()
    manualTextNode.verticalAlignmentMode = .Center
    manualTextNode.fontSize = 18.0
    manualTextNode.text = "Ask Mom For Money (+$1)"
    manualNode.addChild(manualTextNode)
    addChild(manualNode)
    
    // Create programmer labels
    let programmerNodeSize = CGSize(width: 320.0, height: 64.0)
    let programmerNodePositionX = size.width - (programmerNodeSize.width / 2) - 20.0
    var programmerNodePositionY = size.height - (programmerNodeSize.height / 2) - 20.0
    
    ProgrammerType.allValues.forEach { [unowned self] type in
      guard let count = self.company.programmers[type] else {
        return
      }
      
      let node = SKShapeNode(rectOfSize: programmerNodeSize, cornerRadius: 12.0)
      node.position.x = programmerNodePositionX
      node.position.y = programmerNodePositionY
      node.fillColor = SKColor.whiteColor()
      node.strokeColor = SKColor.clearColor()
      
      let nameLabel = SKLabelNode(fontNamed: "OperatorMono-Book")
      nameLabel.fontColor = SKColor.darkGrayColor()
      nameLabel.fontSize = 16.0
      nameLabel.text = "\(type.name) - $\(type.costForCount(count))"
      nameLabel.verticalAlignmentMode = .Center
      node.addChild(nameLabel)
      
      self.addChild(node)
      self.programmerNodes[type] = node
      
      programmerNodePositionY = programmerNodePositionY - programmerNodeSize.height - 20.0
    }
  }
  
  override func mouseUp(theEvent: NSEvent) {
    let location = theEvent.locationInNode(self)
  
    if manualNode.containsPoint(location) {
      self.company.returnBottles(amount: 1)
      return;
    }
    
    programmerNodes.forEach { (type, node) in
      let count = self.company.programmers[type]!
      
      if (node.containsPoint(location)) {
        if (self.company.ableToHire(type: type, withCount: count + 1)) {
          self.company.hire(type: type)
        }
        else {
          print("Can't buy that!")
        }
      }
    }
  }
  
  override func update(currentTime: CFTimeInterval) {
    let deltaTime: CFTimeInterval = currentTime - lastUpdateTime
    
    company.tick(deltaTime: deltaTime)
    updateMoneyInfo()
    updateProgrammerInfo()

    lastUpdateTime = currentTime
  }
  
  func updateMoneyInfo() {
    let displayMoney = String(format: "%.02f", company.money)

    moneyLabel.text = "Money: $\(displayMoney) - ($\(company.incomePerSecond()) / second)"
    moneyLabel.position = CGPoint(x: 20, y: companyLabel.position.y - companyLabel.frame.height - 20.0)
  }
  
  func updateProgrammerInfo() {
    programmerNodes.forEach { [unowned self] (type, node) in
      let cost = Double(type.costForCount(self.company.programmers[type]! + 1))
      let textNode = node.children.first as! SKLabelNode
      textNode.text = "\(type.name) - (+$\(type.production)/s) - $\(cost)"
      
      if (self.company.money < cost) {
        node.alpha = 0.75
      }
      else {
        node.alpha = 1.0
      }
    }
  }
}
