//
//  TableViewCell.swift
//  MyContacts
//
//  Created by Mallikharjuna avula on 11/11/19.
//  Copyright © 2019 Mallikharjuna avula. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    var item: myContact?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
