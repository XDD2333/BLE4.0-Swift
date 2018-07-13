//
//  LogView.swift
//  BLE4.0
//
//  Created by xd on 2018/7/9.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import UIKit

let cellId: String = "cellID"


class LogView: UIView, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var logView: UIView!
    
    var arrDatas: NSMutableArray = NSMutableArray.init()
    
    override func awakeFromNib() {
        logView = UINib.init(nibName: "LogView", bundle: nil).instantiate(withOwner: self, options: nil).last as! UIView
        logView.frame = self.bounds
        self.addSubview(logView)
        tableView.register(UINib.init(nibName: "LogCell", bundle: nil), forCellReuseIdentifier: cellId)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrDatas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: LogCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! LogCell
        
        let str: String = arrDatas[indexPath.row] as! String
        cell.setData(str)
        
        return cell
    }
    
    // MAKR: Actions
    func addLog(_ text: String) {
        if arrDatas.count > 500 {
            arrDatas.removeObjects(in: NSMakeRange(0, 300))
            tableView.reloadData()
        }
        
        arrDatas.add(text)
        tableView.insertRows(at: [IndexPath.init(row: arrDatas.count - 1, section: 0)], with:UITableViewRowAnimation.none)
        tableView.scrollToRow(at: IndexPath.init(row: arrDatas.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
    }
    
    func clear() {
        arrDatas.removeAllObjects()
        tableView.reloadData()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
