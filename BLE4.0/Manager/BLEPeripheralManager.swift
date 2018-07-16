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
    }
    
    // 取消了订阅
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        log("取消订阅了特征:  \(characteristic.uuid.uuidString)")
    }
    
    // 读characteristics请求
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue > 0 {
            let data: Data = request.characteristic.value!
            request.value = data
            log("中心设备成功读取: \(data.description)")
            peripheralManager?.respond(to: request, withResult: .success)
        } else {
            log("中心设备读取失败: 没有读取权限")
            peripheralManager?.respond(to: request, withResult: .readNotPermitted)
        }
    }
    
    // 写characteristics请求
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request: CBATTRequest in requests {
            if request.characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue > 0 {
                let characteristic: CBMutableCharacteristic = request.characteristic as! CBMutableCharacteristic
                characteristic.value = request.value
                let data: DataModel = DataModel.init(recevied: request.value!)
                log("中心设备成功写入: \(String(describing: data.dataContent?.description))")
                if data.command == .receiveDataSuccess {
                    let index: Int = DataTransferHandle.hexToInt(number: DataTransferHandle.toHex(data: data.dataContent!))
                    if index < arrDataNeedSend!.count {
                        let needSendData = arrDataNeedSend![index]
                        peripheralManager!.updateValue(needSendData.getData(), for: curCharacteristics![0], onSubscribedCentrals: nil)
                    } else {
                        let lastPacket: DataModel = DataModel.init(sendFinish: arrDataNeedSend!.count)
                        peripheralManager!.updateValue(lastPacket.getData(), for: curCharacteristics![0], onSubscribedCentrals: nil)
                    }
                    
                } else if data.command == .readyForReceiveData {
                    /// 发送第一个数据包
                    let needSendData = arrDataNeedSend?.first
                    peripheralManager!.updateValue(needSendData!.getData(), for: curCharacteristics![0], onSubscribedCentrals: nil)
                }
                
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
    
    func sendData() {
        let singleData: DataModel = DataModel.init(sendSingleData: Int(arc4random() % 1000))
        peripheralManager!.updateValue(singleData.getData(), for: curCharacteristics![0], onSubscribedCentrals: nil)
    }
    
    func sendMultipleData() {
        if arrDataNeedSend == nil {
            let image: UIImage = UIImage.init(named: "emoji")!
            let data: Data = UIImageJPEGRepresentation(image, 0.9)!
            //            let data: Data = UIImagePNGRepresentation(image)!
            
            arrDataNeedSend = DataTransferHandle.splitPackets(with : data)
        }
        
        let firstPacket: DataModel = DataModel.init(sendStart: arrDataNeedSend!.count)
        peripheralManager!.updateValue(firstPacket.getData(), for: curCharacteristics![0], onSubscribedCentrals: nil)
    }
}
