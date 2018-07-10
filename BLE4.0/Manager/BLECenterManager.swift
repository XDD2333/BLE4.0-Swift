//
//  BLECenterManager.swift
//  BLE4.0
//
//  Created by xd on 2018/6/29.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

public let deviceName: String = "BLE_Device"

public let ServiceUUID = "F000"
public let CharacteristicUUID_Notify = "F001"
public let CharacteristicUUID_Write = "F002"

let kConnectTimeOut = 5


import Foundation
import CoreBluetooth

class BLECenterManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let sharedManager: BLECenterManager = BLECenterManager()
    var centerManager: CBCentralManager?
    var curName: String?
    var curPeripheral: CBPeripheral?

    var logDelegate: LogDelegate?
    
    
    /// MARK: Init
    private override init() {
        super.init()
        centerManager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
    }
    
    /// 开始扫描外设
    func scan() {
        centerManager!.scanForPeripherals(withServices: [CBUUID.init(string: ServiceUUID)], options: [:])
    }
    
    func stopScan() {
        centerManager!.stopScan()
    }
    
    func disConnect() {
        if curPeripheral != nil {
            centerManager!.cancelPeripheralConnection(curPeripheral!)
        }
    }
    
    func stopAll() {
        stopScan()
        disConnect()
    }
    
    func reScan() {
        curName = ""
        curPeripheral = nil
        scan()
        log("重新扫描")
    }
    
    /// MARK: CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            log("unknown")
        case .resetting:
            log("resetting")
        case .unauthorized:
            log("unauthorized")
        case .unsupported:
            log("unsupported")
        case .poweredOff:
            log("poweredOff")
        case .poweredOn:
            log("poweredOn")
            self.scan()
        }
    }
    
    /// 发现外设
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = advertisementData["kCBAdvDataLocalName"] {
            log("[FOUND] ad device: \(name), RSSI: \(RSSI)db")
            curName = name as? String
            if name as! String == deviceName {
                self.connect(peripheral: peripheral)
            }
        }
    }
    
    /// 开始连接
    func connect(peripheral: CBPeripheral) {
        if peripheral.state == .disconnected {
            stopScan()
            curPeripheral = peripheral
            log("[CONNECT] device: \(String(describing: curName))")
            centerManager!.connect(peripheral, options: [:])
            self.perform(#selector(handleConnectTimeOut), with: nil, afterDelay: TimeInterval(kConnectTimeOut))
        } else {
            centerManager!.cancelPeripheralConnection(peripheral)
        }
    }
    
    /// 连接超时处理
    @objc func handleConnectTimeOut() {
        log("[CONNECT] device time out: \(String(describing: curName))")
        centerManager!.cancelPeripheralConnection(curPeripheral!)
        reScan()
    }
    
    // MARK: 连接回调
    /// 连接成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("[CONNECT] success")
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(handleConnectTimeOut), object: nil)

        // 连接成功，开始扫描外设的服务
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    /// 断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log("[DISCONNECT]:\(String(describing: error?.localizedDescription))")
        reScan()
    }
    
    /// 连接失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("[CONNECT] fail:\(String(describing: error?.localizedDescription))")
        reScan()
    }
    
    
    // MARK: CBPeripheralDelegate
    /// 发现服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for aService in (peripheral.services)! {
            if aService.uuid.uuidString == ServiceUUID {
                log("发现服务: UUID:\(aService.uuid.uuidString)")
                peripheral.discoverCharacteristics(nil, for: aService)
            }
        }
    }
    
    /// 发现特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for aCharacteristic in service.characteristics! {
            log("发现特征: \(aCharacteristic.description)")
            if aCharacteristic.uuid.uuidString.compare(CharacteristicUUID_Notify) == .orderedSame {
                curPeripheral?.setNotifyValue(true, for: aCharacteristic)
            }
        }
    }
    
    /// 数据更新
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            log("接收数据错误: \(String(describing: error?.localizedDescription))")
        } else {
            log("收到数据: \(String(describing: String.init(data: characteristic.value!, encoding: String.Encoding.utf8)))")
        }
    }
    
    /// 数据写入回调
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            log("写入数据错误: \(String(describing: error?.localizedDescription))")
        } else {
            log("写入数据成功: \(String(describing: String.init(data: characteristic.value!, encoding: String.Encoding.utf8)))")
        }
    }
    
    func log(_ text: String) {
        print(text)
        if logDelegate != nil {
            logDelegate!.logMsg(text)
        }
    }
}
