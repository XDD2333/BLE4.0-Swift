//
//  DataModel.swift
//  BLE4.0
//
//  Created by xd on 2018/7/12.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation

public let dataHeader: UInt8 = 0xff /// 数据包header

/// command
enum DataCommand: UInt8 {
    case singleData = 0x01             /// 单条完整数据
    case multipleDataStart = 0x02      /// 分包数据开始发送（发送分包数量）示例 FF 02 02 02 04
    case multipleDataTransfer = 0x03   /// 分包数据传输中
    case multipleDataFinish = 0x04     /// 分包数据发送完毕
    
    /// centerManager
    case readyForReceiveData = 0x10    /// 中心设备通知外设，已准备好接收数据
}

class DataModel: NSObject {
    var header: UInt8?
    var command: DataCommand?
    var length: UInt8?
    var dataContent: Data?
    var checkSum: UInt8?
    var isValid: Bool = false
    
    
    override init() {
        super.init()
        
    }
    
    init(recevied data: Data) {
        super.init()
        header = data[0]
        command = DataCommand(rawValue: data[1])
        length = data[2]
        
        let lengthInt = Int(littleEndian: Int(length!))
        let range: ClosedRange = 3...(2 + lengthInt)
        dataContent = data.subdata(in: Range.init(range))
        
        print("2")
        checkSum = data.last
        isValid = checkSum == DataTransferHandle.getCheckSum(dataContent!, length!)
    }
    
    init(send data: Data?) {
        super.init()
        
        header = dataHeader
        command = DataCommand.multipleDataTransfer
        length = UInt8(data!.count)
        dataContent = data
//        checkSum = DataTransferHandle.getCheckSum(dataString!, length!)
    }
    
    init(sendStart packets: Int) {
        super.init()
        header = dataHeader
        command = DataCommand.multipleDataStart
//        length = 4
//        dataString = DataTransferHandle.toHex(num: packets)
//        if dataString!.count < 4 {
//            let count = 4 - dataString!.count - 1
//            var prefix = ""
//            for _ in 0...count {
//                prefix = prefix + "0"
//            }
//            dataString = prefix + dataString!
//        }
//        checkSum = DataTransferHandle.getCheckSum(dataString!, length!)
    }
    
    init(sendFinish packets: Int) {
        header = dataHeader
        command = DataCommand.multipleDataFinish
        length = 4
//        dataString = DataTransferHandle.toHex(num: packets)
//        if dataString!.count < 4 {
//            let count = 4 - dataString!.count - 1
//            var prefix = ""
//            for _ in 0...count {
//                prefix = prefix + "0"
//            }
//            dataString = prefix + dataString!
//        }
//        checkSum = DataTransferHandle.getCheckSum(dataString!, length!)
    }
    
    /// 准备需要发送的数据包
    func getData() -> Data {
        var data: Data = Data()
        
        /// header
//        data.append(DataTransferHandle.dataWithHexString2(str: header! as NSString))
//        
//        /// commond
//        data.append(DataTransferHandle.dataWithHexString2(str: command!.rawValue as NSString))
//
//        /// length
//        let lengthHexStr = DataTransferHandle.toHex(num: length!)
//        data.append(DataTransferHandle.dataWithHexString2(str: lengthHexStr as NSString))
//
//        /// data
//        data.append(dataString!.data(using: String.Encoding.utf8)!)
//
//        /// checkSum
//        let SumHexStr = DataTransferHandle.toHex(num: checkSum!)
//        data.append(DataTransferHandle.dataWithHexString2(str: SumHexStr as NSString))
        
        return data
    }
}
