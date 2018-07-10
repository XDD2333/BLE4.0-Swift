//
//  BLEPeripheralManager.swift
//  BLE4.0
//
//  Created by xd on 2018/6/29.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLEPeripheralManager: NSObject, CBPeripheralManagerDelegate {
    static let sharedManager: BLEPeripheralManager = BLEPeripheralManager()
    var peripheralManager: CBPeripheralManager?
    var timer: Timer?
    
    var logDelegate: LogDelegate?
    
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager.init(delegate: self, queue: DispatchQueue.main)
    }
    
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
    }
    
    func startAdvertising() {
        config()
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
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
            config()
        }
    }
    
    func config() {
        peripheralManager!.removeAllServices()
        /// 配置Characteristic
        let characteristicNotify: CBMutableCharacteristic = CBMutableCharacteristic.init(type: CBUUID.init(string: CharacteristicUUID_Notify), properties: .notify, value: nil, permissions: .readable)
        
        let characteristicWrite: CBMutableCharacteristic = CBMutableCharacteristic.init(type: CBUUID.init(string: CharacteristicUUID_Write), properties: .write, value: nil, permissions: .writeable)

        /// 配置Service
        let service: CBMutableService = CBMutableService.init(type: CBUUID.init(string: ServiceUUID), primary: true)
        service.characteristics = [characteristicNotify, characteristicWrite]
        
        peripheralManager!.add(service)
        log("配置完成")
    }
    
    // MARK: CBPeripheralManagerDelegate
    /// 添加服务回调
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if error != nil {
            log("添加服务失败: \(error!.localizedDescription)")
        } else {
            log("添加服务成功, 开始广播")
            /// 服务添加成功后，开始发送广播
            peripheralManager!.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [service.uuid], CBAdvertisementDataLocalNameKey: deviceName])
        }
    }
    
    /// 发送广播回调
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let err = error {
            log("发送广播失败: \(err.localizedDescription)")
        } else {
            log("发送广播成功")
        }
    }
    
    // MARK: 订阅
    /// 开启了订阅
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        log("订阅了特征: \(characteristic.uuid.uuidString)")
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(notifyData(aTimer:)), userInfo: characteristic, repeats: true)
        timer?.fireDate = Date.init()
    }
    
    // 取消了订阅
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        log("取消订阅了特征:  \(characteristic.uuid.uuidString)")
        timer?.invalidate()
    }
    
    // 向中心设备发送数据
    @objc func notifyData(aTimer: Timer) -> Bool {
        let characteristic: CBMutableCharacteristic = aTimer.userInfo as! CBMutableCharacteristic
        let formatter: DateFormatter = DateFormatter.init()
        formatter.dateFormat = "ss"
        
        let dateStr: String = formatter.string(from: Date.init())
        let data: Data = dateStr.data(using: String.Encoding.utf8)!
        
        log("发送数据: \(dateStr)")
        return peripheralManager!.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
    }
    
    // 读characteristics请求
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        log("收到读characteristics请求")
        if request.characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue > 0 {
            let data: Data = request.characteristic.value!
            request.value = data
            log("中心设备成功读取: \(data.description)")
            peripheralManager?.respond(to: request, withResult: .success)
        } else {
            log("中心设备读物失败: 没有读取权限")
            peripheralManager?.respond(to: request, withResult: .readNotPermitted)
        }
    }
    
    // 写characteristics请求
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        log("收到读characteristics请求: \(requests.count)个")
        for request: CBATTRequest in requests {
            if request.characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue > 0 {
                let characteristic: CBMutableCharacteristic = request.characteristic as! CBMutableCharacteristic
                characteristic.value = request.value
                log("中心设备成功写入: \(String(describing: request.value?.description))")
                peripheralManager?.respond(to: request, withResult: .success)
            } else {
                log("中心设备写入失败: 没有写入权限")
                peripheralManager?.respond(to: request, withResult: .writeNotPermitted)
            }
        }
    }
    
    func log(_ text: String) {
        print(text)
        if logDelegate != nil {
            logDelegate!.logMsg(text)
        }
    }
}
