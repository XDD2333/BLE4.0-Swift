//
//  RootViewController.swift
//  BLE4.0
//
//  Created by xd on 2018/6/29.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation
import UIKit

class RootViewController: UIViewController {
    override func viewDidLoad() {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }

    @IBAction func centerAction(_ sender: Any) {
        let centerVC = CenterViewController.init(nibName: "CenterViewController", bundle: nil)
        self.navigationController!.pushViewController(centerVC, animated: true)
    }
    
    @IBAction func peripheralAction(_ sender: Any) {
        let peripheralVC = PeripheralViewController.init(nibName: "PeripheralViewController", bundle: nil)
        self.navigationController!.pushViewController(peripheralVC, animated: true)
    }
}
