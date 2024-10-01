//
//  NumberTableViewCell.swift
//  MyContacts
//
//  Created by Mallikharjuna avula on 12/11/19.
//  Copyright © 2019 Mallikharjuna avula. All rights reserved.
//

import UIKit

protocol numberCellDelegate: class{
    func deleteField(_ sender: UIButton!)
}

class NumberTableViewCell: UITableViewCell {

    @IBAction func deleteFieldOfCell(_ sender: UIButton) {
        delegate?.deleteField(sender)
    }
    
    weak var delegate: numberCellDelegate?
    
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var phoneText: UITextField!
    
    override func awakeFromNib() {
        //removeButton.addTarget(NewContactViewController.self, action: #selector(NewContactViewController.deleteField(_:)), for: .touchUpInside)
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
