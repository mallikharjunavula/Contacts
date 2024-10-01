//
//  NewContactViewController.swift
//  MyContacts
//
//  Created by Mallikharjuna avula on 08/11/19.
//  Copyright © 2019 Mallikharjuna avula. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxRelay

class NewContactViewController: UIViewController, UITableViewDelegate, UITextFieldDelegate, numberCellDelegate{

    @IBOutlet weak var photoView: UIView!
    @IBOutlet weak var save: UIBarButtonItem!
    @IBOutlet weak var cancel: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var label: UILabel!
    
    var updatingContact = BehaviorRelay<[SectionModel<String, contactCells>]>(value: [])
    var presentContact: myContact?
    let disposeBag = DisposeBag()
    var phoneCount = 0
    var addressCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.KeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        updatingContact.accept([SectionModel(model: "Name",items: [contactCells.name([])]),SectionModel(model: "Phone", items: [contactCells.numbers(label: "", details: "")]),SectionModel(model: "address", items: [contactCells.address(label: "", details:  "")])])
        
        if ((self.presentingViewController as? DetailContactViewController) != nil){
            updatingContact.accept([SectionModel(model: "Name",items: [contactCells.name([])]),SectionModel(model: "Phone", items: [contactCells.numbers(label: "", details: "")]),SectionModel(model: "address", items: [contactCells.address(label: "", details:  "")]),SectionModel(model: "delete", items: [contactCells.delete])])
        }
        
        if let contact = presentContact{
            updatingContact.append("Name", contact.name, contact.middleName, contact.familyName)
            for (index,label) in contact.phoneNumberLabel.enumerated(){
                updatingContact.append("Phone",label, contact.phoneNumber[index])
                phoneCount += 1
            }
            for (index,label) in contact.addressLabel.enumerated(){
                updatingContact.append("address",label, contact.addressDetails[index])
                addressCount += 1
            }
        }
        
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        save.isEnabled = false
        photoView.layer.cornerRadius = 50.0
        photoView.backgroundColor = .lightGray
        if let contact = presentContact{
            label.text = contact.fullName
        }
        
        //MARK: CANCEL SUBSCRIPTION
        
        cancel.rx.tap.subscribe(onNext:{
            let vc = UIAlertController(
                title: "exit",
                message: "really want to exit or keep changing",
                preferredStyle: .actionSheet
            )
            let keep = UIAlertAction(
                title: "Keep changes",
                style: .default,
                handler: {action in
                    UIApplication.shared.sendAction(self.save.action!, to: self.save.target, from: self, for: nil)
            })
            let dismiss = UIAlertAction(
                title: "Discard Changes",
                style: .destructive,
                handler: { action in
                    self.dismiss(animated: true)
                    self.presentingViewController?.navigationController?.setNavigationBarHidden(false, animated: false)
            })
            vc.addAction(keep)
            vc.addAction(dismiss)
            if let popoverController = vc.popoverPresentationController{
                popoverController.barButtonItem = self.cancel
            }
            self.present(vc, animated: true)
        })
        .disposed(by: disposeBag)
        
        //MARK: TABLEVIEW DATA SOURCE
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String,contactCells>>(configureCell: {dataSource, table, indexPath, item in
            switch item{
            case .name(let name):
                let cell = table.dequeueReusableCell(withIdentifier: "NameCell",for: indexPath)
                if let nameCell = cell as? NameTableViewCell, !name.isEmpty{
                    nameCell.name.text = name[0]
                    nameCell.middlename.text = name[1]
                    nameCell.familyName.text = name[2]
                }
                return cell
                
            case .numbers(let phoneNumbers):
                if indexPath.row == self.phoneCount{
                    let cell = table.dequeueReusableCell(withIdentifier: "AddPhone",for: indexPath)
                    return cell
                }
                else{
                    let cell = table.dequeueReusableCell(withIdentifier: "NewPhone",for: indexPath)
                    if let numberCell = cell as? NumberTableViewCell, phoneNumbers.label != ""{
                        numberCell.delegate = self
                        numberCell.phoneText.text = phoneNumbers.details
                        numberCell.phoneText.placeholder = phoneNumbers.label
                        numberCell.removeButton.setTitle("❌ \(phoneNumbers.label)", for: .normal)
                        numberCell.removeButton.accessibilityLabel = "\(indexPath.row)\(indexPath.section)"
                    }
                    return cell
                }
            case .address(let address):
                if indexPath.row == self.addressCount{
                    let cell = table.dequeueReusableCell(withIdentifier: "AddPhone",for: indexPath)
                    return cell
                }
                else{
                    let cell = table.dequeueReusableCell(withIdentifier: "NewPhone",for: indexPath)
                    if let numberCell = cell as? NumberTableViewCell, address.label != ""{
                        numberCell.delegate = self
                        numberCell.phoneText.text = address.details
                        numberCell.phoneText.placeholder = address.label
                        numberCell.removeButton.setTitle(String("❌ \(address.label)".dropLast(7)), for: .normal)
                        numberCell.removeButton.accessibilityLabel = "\(indexPath.row)\(indexPath.section)"
                    }
                    return cell
                }
            case .delete:
                let cell = table.dequeueReusableCell(withIdentifier: "DeleteContact", for: indexPath)
                if let newCell = cell as? DeleteTableViewCell{
                    newCell.deleteLabel.layer.cornerRadius = 10.0
                }
                return cell
            }
        })
        
        dataSource.canEditRowAtIndexPath = { dataSource, indexPath in
            return true
        }
        
        updatingContact
        .bind(to: tableView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        save.rx.tap.subscribe(onNext:{ [weak self] in
            let vm = ViewModel()
            vm.saveConatacts(old: self?.presentContact, new: (self?.updatingContact.value)!)
            self?.presentingViewController?.navigationController?.setNavigationBarHidden(false, animated: false)
            let vc = self?.presentingViewController as? DetailContactViewController
            vc?.item.accept(myContact(model: self?.updatingContact.value))
            self?.dismiss(animated: true)
        })
        .disposed(by: disposeBag)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            self.tableView.beginUpdates()
            updatingContact.append("Phone", "Mobile\(indexPath.row)", "")
            phoneCount += 1
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
            self.tableView.endUpdates()
        }
        if indexPath.section == 2 {
            self.tableView.beginUpdates()
            updatingContact.append("address", "homeaddress\(indexPath.row)", "")
            addressCount += 1
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
            self.tableView.endUpdates()
        }
        if indexPath.section == 3{
            var vm = (UIApplication.shared.delegate as! AppDelegate).vm
            vm.deleteContact(presentContact!)
            self.presentingViewController?.navigationController?.setNavigationBarHidden(false, animated: false)
            if let vc = self.presentingViewController as? DetailContactViewController{
                vc.compactDismiss = true
            }
            self.dismiss(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
            return 0.0
        }
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0{
            return 104.0
        }
        return 40.0
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        save.isEnabled = true
        if let placeholder = textField.placeholder, let text = textField.text{
            updatingContact.modify(placeholder,text)
        }
    }
    
    @objc func KeyboardWillShow(notification: NSNotification){
        guard let userInfo = notification.userInfo else {return}
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let keyboardFrame = keyboardSize.cgRectValue
        if self.view.frame.origin.y == 0{
            self.view.frame.origin.y -= keyboardFrame.height/2
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        guard let userInfo = notification.userInfo else {return}
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let keyboardFrame = keyboardSize.cgRectValue
        if self.view.frame.origin.y != 0{
            self.view.frame.origin.y += keyboardFrame.height/2
        }
    }
    
    func deleteField(_ sender: UIButton!){
        if let index = sender.accessibilityLabel, let rowSection = Int(index){
            let section = rowSection % 10
            let row = (rowSection/10) % 10
            let vc = UIAlertController(
                title: "Delete",
                message: "permanently Delete the item",
                preferredStyle: .actionSheet
            )
            let keep = UIAlertAction(
                title: "No",
                style: .default,
                handler: {action in
                    
            })
            let dismiss = UIAlertAction(
                title: "Delete",
                style: .destructive,
                handler: { action in
                    self.tableView.performBatchUpdates({
                    if let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: section)) as? NumberTableViewCell{
                        switch section{
                        case 1: self.updatingContact.delete(cell.phoneText.placeholder!,"Phone")
                                self.phoneCount -= 1
                            break
                        case 2: self.updatingContact.delete(cell.phoneText.placeholder!,"address")
                                self.addressCount -= 1
                            break
                        default:
                            break
                        }
                        self.tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: .fade)
                        self.tableView.reloadData()
                    }
                })
            })
            vc.addAction(keep)
            vc.addAction(dismiss)
            if let popoverController = vc.popoverPresentationController{
                popoverController.barButtonItem = self.cancel
            }
            self.present(vc, animated: true)
        }
    }
}
