//
//  PeripheralViewController.swift
//  BLE4.0
//
//  Created by xd on 2018/6/29.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation
import UIKit

class PeripheralViewController: UIViewController, LogDelegate {
    
    @IBOutlet weak var logView: LogView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "外设"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if BLECenterManager.sharedManager.logDelegate != nil {
            BLEPeripheralManager.sharedManager.startAdvertising()
        } else {
            BLEPeripheralManager.sharedManager.logDelegate = self
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BLEPeripheralManager.sharedManager.stopAdvertising()
    }
    
    func logMsg(_ text: String) {
        logView.addLog(text)
    }
    
    @IBAction func startAction(_ sender: Any) {
        BLEPeripheralManager.sharedManager.startAdvertising()
    }
    
    @IBAction func stopAction(_ sender: Any) {
        BLEPeripheralManager.sharedManager.stopAdvertising()
    }
    
    @IBAction func sendSingleData(_ sender: Any) {
        BLEPeripheralManager.sharedManager.sendData()
    }
    
    @IBAction func sendMultipleData(_ sender: Any) {
        BLEPeripheralManager.sharedManager.sendMultipleData()
    }
}
