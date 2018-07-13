//
//  CenterViewController.swift
//  BLE4.0
//
//  Created by xd on 2018/6/29.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import Foundation
import UIKit

class CenterViewController: UIViewController, LogDelegate, BLECenterManagerDelegate {
    
    @IBOutlet weak var logView: LogView!
    @IBOutlet weak var reScan: UIButton!
    @IBOutlet weak var disConnect: UIButton!
    
    @IBOutlet weak var duplicateSwitch: UISwitch!
    @IBOutlet weak var searchLimitSwitch: UISwitch!
    @IBOutlet weak var onlyScanSwitch: UISwitch!
    @IBOutlet weak var lblRSSI: UILabel!
    @IBOutlet weak var progressRSSI: UIProgressView!
    
    var arrDataNeedTransfer: [DataModel]?   /// 需要传输的数据分包数组
    var dataReceived: Data = Data()
    var totalPacketCount: Int?            /// 总分包数
    var receivedPackets: Int?             /// 已经接收的分包数
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "中心设备"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BLECenterManager.sharedManager.logDelegate = self
        BLECenterManager.sharedManager.eventDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BLECenterManager.sharedManager.stopAll()
    }

    /// 重新扫描
    @IBAction func ReScanAction(_ sender: Any) {
        BLECenterManager.sharedManager.reScan()
    }
    
    /// 断开连接
    @IBAction func DisConnectAction(_ sender: Any) {
        BLECenterManager.sharedManager.disConnect()
    }
    
    /// 清空log
    @IBAction func clearAcrion(_ sender: Any) {
        logView.clear()
    }
    
    
    // MARK: SwitchAction
    /// 是否允许重复发现设备
    @IBAction func allowDuplicateValueChanged(_ sender: UISwitch) {
        BLECenterManager.sharedManager.allowDuplicate = sender.isOn
        BLECenterManager.sharedManager.reScan()
    }
    
    /// 是否只搜索指定设备
    @IBAction func serachLimitValueChanged(_ sender: UISwitch) {
        BLECenterManager.sharedManager.onlyBLE = sender.isOn
        BLECenterManager.sharedManager.reScan()
    }
    
    /// 是否只扫描不连接
    @IBAction func onlySearchValueChanged(_ sender: UISwitch) {
        BLECenterManager.sharedManager.onlyScan = sender.isOn
        BLECenterManager.sharedManager.reScan()
    }
    
    
    // MARK: LogDelegate
    func logMsg(_ text: String) {
        logView.addLog(text)
    }
    
    
    // MARK: EventDelegate
    func bleCenterManagerRSSIupdated(_ RSSI: NSNumber) {
        lblRSSI.text = String.init(format: "%@", RSSI)
        
        let RSSI_Int: Int = RSSI.intValue + 127
        progressRSSI.progress = Float(RSSI_Int) / 127.0
    }
    
    /// 数据接收后的处理
    func bleDidUpdateValue(_ data: DataModel, _ error: Error?) {
        var logHeader: String?
    
        switch data.command! {
        case .singleData:
            logHeader = "[DATA]收到单条数据, 校验结果: \(data.isValid) value: \(String(describing: data.dataContent!.description))"
        case .multipleDataStart:
            logHeader = "[DATA]开始接收分包数据, 校验结果: \(data.isValid) 分包数: \(DataTransferHandle.hexToInt(number: data.dataContent!.description))"
            totalPacketCount = DataTransferHandle.hexToInt(number: data.dataContent!.description)
            receivedPackets = 0
        case .multipleDataTransfer:
            receivedPackets! = receivedPackets! + 1
            logHeader = "[DATA]收到第\(String(describing: receivedPackets))个包, 校验结果: \(data.isValid) 进度: /\(String(describing: totalPacketCount))"
        case .multipleDataFinish:
            logHeader = "[DATA]分包数据接收完毕"
        
        default:
            print("default")
        }
        
        logMsg(logHeader!)
        
        if data.isValid {
            /// 拼接数据包
            let packet: Data = data.dataContent!
            dataReceived.append(packet)
            
            /// 数据校验成功，发送回执，接收下一个包
            let indexStr: String = DataTransferHandle.toHex(num: receivedPackets!)
            let sendData: Data = indexStr.data(using: String.Encoding.utf8)!
            BLECenterManager.sharedManager.writeData(sendData)
        }
    }
    
    func bleDidWriteValue(_ data: Data, _error: Error?) {
        
    }
}
