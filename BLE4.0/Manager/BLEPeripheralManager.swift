//
//  BLEPeripheralManager.swift
//  BLE4.0
//
//  Created by xd on 2018/6/29.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class BLEPeripheralManager: NSObject, CBPeripheralManagerDelegate {
    static let sharedManager: BLEPeripheralManager = BLEPeripheralManager()
    var peripheralManager: CBPeripheralManager?
    var curCharacteristics: [CBMutableCharacteristic]?
    var curService: CBMutableService?
    
    var arrDataNeedSend: [DataModel]?
    var didStartSend: Bool = false
    
//    var timer: Timer?
    var logDelegate: LogDelegate?
    
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager.init(delegate: self, queue: DispatchQueue.main)
    }
    
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
    }
    
    func startAdvertising() {
        if (peripheralManager?.isAdvertising)! {
            stopAdvertising()
        }
        
        if let service = curService {
            peripheralManager!.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [service.uuid], CBAdvertisementDataLocalNameKey: deviceName])
        } else {
            config()
        }
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
        curCharacteristics = [characteristicNotify, characteristicWrite]
        service.characteristics = curCharacteristics
        curService = service
        
        peripheralManager!.add(curService!)
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
        
        let firstPacket: DataModel = DataModel.init(sendStart: 16)
        let data: Data = firstPacket.getData()
        
        peripheralManager!.updateValue(firstPacket.getData(), for: curCharacteristics![0], onSubscribedCentrals: nil)
        
        return
        if arrDataNeedSend == nil {
            let image: UIImage = UIImage.init(named: "emoji")!
            let data: Data = UIImagePNGRepresentation(image)!
            arrDataNeedSend = DataTransferHandle.splitPackets(with : data)
            
            let firstPacket: DataModel = DataModel.init(sendStart: arrDataNeedSend!.count)
            let lastPacket: DataModel = DataModel.init(sendFinish: arrDataNeedSend!.count)
            print("123")
        }
    }
    
    // 取消了订阅
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        log("取消订阅了特征:  \(characteristic.uuid.uuidString)")
    }
    
    // 向中心设备发送数据
    func notifyData() {
//        peripheralManager!.updateValue(data, for: curCharacteristics![0], onSubscribedCentrals: nil)
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
