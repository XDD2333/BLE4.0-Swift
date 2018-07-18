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
    @IBOutlet weak var transferProgress: UIProgressView!
    @IBOutlet weak var lblTransfer: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
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
    
    func bleDidWriteValue(_ data: Data, _error: Error?) {
        
    }
    
    /// 数据接收后的处理
    func bleDidUpdateValue(_ data: DataModel, _ error: Error?) {
        var logHeader: String?
    
        switch data.command! {
        case .singleData:
            logHeader = "[DATA]收到单条数据, 校验结果: \(data.isValid) value: \(DataTransferHandle.toHex(data: data.dataContent!))"
        case .multipleDataStart:
            imageView.image = nil
            transferProgress.progress = 0
            logHeader = "[DATA]开始接收分包数据, 校验结果: \(data.isValid) 分包数: \(DataTransferHandle.hexToInt(number: DataTransferHandle.toHex(data: data.dataContent!)))"
            
            if data.isValid {
                /// 初始化，准备接收数据
                totalPacketCount = DataTransferHandle.hexToInt(number: data.dataContent!.description)
                receivedPackets = 1
                dataReceived.removeAll()
                
                /// 发送命令，可以开始接收数据
                let dataModel: DataModel = DataModel.init(readyForData: 0)
                BLECenterManager.sharedManager.writeData(dataModel.getData())
            }
            
        case .multipleDataTransfer:
            logHeader = "[DATA]收到第\(String(describing: receivedPackets))个包, 校验结果: \(data.isValid)"
            
            transferProgress.progress = Float(receivedPackets!) / 244.0
            lblTransfer.text = String.init(format: "%.2f%%", transferProgress.progress * 100)
            
            if data.isValid {
                dataReceived.append(data.dataContent!)
                
                /// 发送命令，可以开始下一个数据
                let dataModel: DataModel = DataModel.init(receiveSuc: receivedPackets!)
                receivedPackets! = receivedPackets! + 1
                BLECenterManager.sharedManager.writeData(dataModel.getData())
            }
            
        case .multipleDataFinish:
            logHeader = "[DATA]分包数据接收完毕"
            imageView.image = UIImage.init(data: dataReceived)
            print("finish")
        default:
            print("default")
        }
        
        logMsg(logHeader!)
    }
}
