//
//  AppDelegate.swift
//  Tycoon
//
//  Created by Nico Hämäläinen on 27/03/16.
//  Copyright (c) 2016 sizeof.io. All rights reserved.
//


import Cocoa
import SpriteKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var skView: SKView!
  
  func applicationDidFinishLaunching(aNotification: NSNotification) {
    let sceneSize = CGSize(width: 800, height: 600)
    let scene = GameScene(size: sceneSize)
    scene.scaleMode = .AspectFit
    
    self.skView!.presentScene(scene)
    self.skView!.ignoresSiblingOrder = true
    self.skView!.showsFPS = true
    self.skView!.showsNodeCount = true
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
    return true
  }
}
