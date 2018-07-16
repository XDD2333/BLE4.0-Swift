//
//  DataModel.swift
//  BLE4.0
//
//  Created by xd on 2018/7/12.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation

public let dataHeader: UInt8 = 0xf0 /// 数据包header

/// command
enum DataCommand: UInt8 {
    case singleData = 0x01             /// 单条完整数据
    case multipleDataStart = 0x02      /// 分包数据开始发送（发送分包数量）
    case multipleDataTransfer = 0x03   /// 分包数据传输中
    case multipleDataFinish = 0x04     /// 分包数据发送完毕
    
    /// centerManager
    case readyForReceiveData = 0x10    /// 中心设备通知外设，已准备好接收数据
    case receiveDataSuccess = 0x11     /// 数据接收成功，如果是分包数据，写入分包序号
}

class DataModel: NSObject {
    var header: UInt8?
    var command: DataCommand?
    var length: UInt8?
    var dataContent: Data?
    var checkSum: UInt8?
    var isValid: Bool = false
    
    
    init(recevied data: Data) {
        super.init()
        header = data[0]
        command = DataCommand(rawValue: data[1])
        length = data[2]
        
        let lengthInt = Int(littleEndian: Int(length!))
        let range: ClosedRange = 3...(2 + lengthInt - 1)
        dataContent = data.subdata(in: Range.init(range))
        
        checkSum = data.last
        isValid = checkSum == DataTransferHandle.getCheckSum(dataContent!, length!)
    }
    
    init(send data: Data?) {
        super.init()
        
        header = dataHeader
        command = DataCommand.multipleDataTransfer
        length = UInt8(data!.count) + UInt8(1)
        dataContent = data
        checkSum = DataTransferHandle.getCheckSum(dataContent!, length!)
    }
    
    init(sendSingleData num: Int) {
        super.init()
        header = dataHeader
        command = DataCommand.singleData
        
        let hexStr = DataTransferHandle.toHex(num: num)
        dataContent = DataTransferHandle.dataWithHexString(str: hexStr as NSString, 1)
        length = UInt8(dataContent!.count) + UInt8(1)
        checkSum = DataTransferHandle.getCheckSum(dataContent!, length!)
    }
    
    init(sendStart packets: Int) {
        super.init()
        header = dataHeader
        command = DataCommand.multipleDataStart
        
        let hexStr = DataTransferHandle.toHex(num: packets)
        dataContent = DataTransferHandle.dataWithHexString(str: hexStr as NSString, 1)
        length = UInt8(dataContent!.count) + UInt8(1)
        checkSum = DataTransferHandle.getCheckSum(dataContent!, length!)
    }
    
    init(sendFinish packets: Int) {
        super.init()
        header = dataHeader
        command = DataCommand.multipleDataFinish
        
        let hexStr = DataTransferHandle.toHex(num: packets)
        dataContent = DataTransferHandle.dataWithHexString(str: hexStr as NSString, 1)
        length = UInt8(dataContent!.count) + UInt8(1)
        checkSum = DataTransferHandle.getCheckSum(dataContent!, length!)
    }
    
    init(readyForData data: Int) {
        super.init()
        header = dataHeader
        command = DataCommand.readyForReceiveData
        length = UInt8(2)
        dataContent = Data.init(bytes: [0])
        checkSum = UInt8(0)
    }
    
    init(receiveSuc Index: Int) {
        super.init()
        header = dataHeader
        command = DataCommand.receiveDataSuccess
        let hexStr = DataTransferHandle.toHex(num: Index)
        dataContent = DataTransferHandle.dataWithHexString(str: hexStr as NSString, 2)
        length = UInt8(dataContent!.count) + UInt8(1)
        checkSum = DataTransferHandle.getCheckSum(dataContent!, length!)
    }
    
    /// 准备需要发送的数据包
    func getData() -> Data {
        var data: Data = Data.init(bytes: [header!, command!.rawValue, length!])
        data.append(dataContent!)
        data.append(checkSum!)
        
        return data
    }
}
