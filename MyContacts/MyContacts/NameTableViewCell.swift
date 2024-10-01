//
//  NameTableViewCell.swift
//  MyContacts
//
//  Created by Mallikharjuna avula on 12/11/19.
//  Copyright © 2019 Mallikharjuna avula. All rights reserved.
//

import UIKit

class NameTableViewCell: UITableViewCell {

    @IBOutlet weak var familyName: UITextField!
    @IBOutlet weak var middlename: UITextField!
    @IBOutlet weak var name: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        name.text = ""
        familyName.text = ""
        middlename.text = ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
