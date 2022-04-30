//
//  File.swift
//  CPingPong
//
//  Created by 林子轩 on 2022/4/30.
//

import Foundation
import UIKit

class mainmenu : UIViewController {
    
    override func viewDidLoad() {
        if !UserDefaults.standard.bool(forKey: "initialized") {
            UserDefaults.standard.setValue(true, forKey: "initialized")
            UserDefaults.standard.setValue("um", forKey: "theme")
            UserDefaults.standard.setValue("um", forKey: "p1")
            UserDefaults.standard.setValue("um", forKey: "p2")
            UserDefaults.standard.setValue("white", forKey: "ball")
        }
    }
    
}
