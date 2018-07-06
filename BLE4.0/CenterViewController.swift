//
//  CenterViewController.swift
//  BLE4.0
//
//  Created by xd on 2018/6/29.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation
import UIKit

class CenterViewController: UIViewController {
    override func viewDidLoad() {
        self.title = "中心设备"
        
        BLECenterManager.sharedManager.scan();
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
}
