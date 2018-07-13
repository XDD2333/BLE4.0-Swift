//
//  DataTransferHandle.swift
//  BLE4.0
//
//  Created by xd on 2018/7/12.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation

class DataTransferHandle: NSObject {
    
    /// data转16进制字符串（2 char -> 1 Byte）
    class func dataWithHexString2(str: NSString) -> Data {
        var data: Data = Data.init()
        for index in stride(from: 0, to: str.length, by: 2) {
            let range: NSRange = NSMakeRange(index, 2)
            let hexStr: String = str.substring(with: range)
            
            let scanner: Scanner = Scanner.init(string: hexStr)
            var intValue: UInt32 = 0
            scanner.scanHexInt32(&intValue)
            
            var char = UInt8(intValue)
            data.append(&char, count: 1)
        }
        
        return data
    }
    
    /// 10进制数字转16进制字符串(num <= 255)
    class func toHex(num: Int) -> String {
        var str = String(num, radix:16)
        if str.count == 1 {
            str = "0" + str
        }
        return str
    }
    
    /// 16进制字符串转Int
    class func hexToInt(number num:String) -> Int {
        let str = num.uppercased()
        var sum = 0
        for i in str.utf8 {
            sum = sum * 16 + Int(i) - 48 // 0-9 从48开始
            if i >= 65 {                 // A-Z 从65开始，但有初始值10，所以应该是减去55
                sum -= 7
            }
        }
        return sum
    }
    
    /// data转16进制字符串
    class func toHex(data: Data) -> String {
        var str: String = ""
        
        for (_, value) in data.enumerated() {
            let strItem: String = String.init(format: "%02X", value)
            str = str + strItem
        }
        
        return str
    }
    
    class func getCheckSum(_ data: Data, _ length: UInt8) -> UInt8 {
        var checkSum: UInt8 = 0
        checkSum = checkSum + length
        
        for value in data {
            checkSum = checkSum + value
        }
        
        return checkSum % UInt8(255)
    }
    
    class func splitPackets(with data: Data) -> [DataModel] {
        var arr: [DataModel] = []
        var tempData: Data = Data()
        
        for (_, value) in data.enumerated() {
            tempData.append(value)
            
            if tempData.count == 16 {
                let dataModel: DataModel = DataModel.init(send: tempData)
                arr.append(dataModel)
                tempData.removeAll()
            }
        }
        
        if tempData.count > 0 {
            let dataModel: DataModel = DataModel.init(send: tempData)
            arr.append(dataModel)
            tempData.removeAll()
        }
        
        return arr
    }
}




