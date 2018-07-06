//
//  BLECenterManager.swift
//  BLE4.0
//
//  Created by xd on 2018/6/29.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLECenterManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let sharedManager: BLECenterManager = BLECenterManager()
    var centerManager: CBCentralManager?
    
    
    private override init() {
        super.init()
        centerManager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
    }
    
    func scan() {
        centerManager!.scanForPeripherals(withServices: nil, options: [:])
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown: break
        case .resetting: break
        case .unauthorized: break
        case .unsupported: break
        case .poweredOff:
            print("Power off")
//            break
        case .poweredOn:
            print("Power on")
            self.scan()
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let data = advertisementData["kCBAdvDataManufacturerData"] {
            print("found device \(String(describing: peripheral.name)), dataName: \(data), rssi: \(RSSI)")
        }
    }
}
