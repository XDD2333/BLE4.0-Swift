//
//  CenterViewController.swift
//  BLE4.0
//
//  Created by xd on 2018/6/29.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation
import UIKit

class CenterViewController: UIViewController, LogDelegate {
    
    @IBOutlet weak var logView: LogView!
    @IBOutlet weak var reScan: UIButton!
    @IBOutlet weak var disConnect: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "中心设备"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BLECenterManager.sharedManager.logDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BLECenterManager.sharedManager.stopAll()
    }
    
    func logMsg(_ text: String) {
        logView.addLog(text)
    }

    @IBAction func ReScanAction(_ sender: Any) {
        BLECenterManager.sharedManager.reScan()
    }
    
    @IBAction func DisConnectAction(_ sender: Any) {
        BLECenterManager.sharedManager.disConnect()
    }
    
}
