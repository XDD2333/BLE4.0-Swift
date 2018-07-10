//
//  LogCell.swift
//  BLE4.0
//
//  Created by xd on 2018/7/9.
//  Copyright © 2018年 Aresmob. All rights reserved.
//

import UIKit

class LogCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setData(_ text: String) {
        label.text = text
    }
    
}
