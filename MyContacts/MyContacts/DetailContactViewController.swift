//
//  DetailContactViewController.swift
//  MyContacts
//
//  Created by Mallikharjuna avula on 11/11/19.
//  Copyright © 2019 Mallikharjuna avula. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxDataSources

class DetailContactViewController: UIViewController,UITableViewDelegate {
        
    @IBOutlet weak var edit2: UIBarButtonItem!
    @IBOutlet weak var edit1: UIButton!
    @IBOutlet weak var edit: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var compactDismiss: Bool = false
    var item = BehaviorRelay<myContact>(value: myContact())
    let disposeBag = DisposeBag()
    
    var model = BehaviorRelay<[SectionModel<String,(label:String,details: String)>]>(value: [])
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String,(label: String,details: String)>>(configureCell: {dataSource, table, indexPath, data in
        let cell = table.dequeueReusableCell(withIdentifier: "Details",for: indexPath)
        if let newCell = cell as? contactFieldTableViewCell{
            newCell.title.text = data.label
            newCell.detail.text = data.details
        }
        return cell
    })
    
    override func viewWillLayoutSubviews(){
        if compactDismiss == true{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.navigationController?.popToRootViewController(animated: true)
            })
            compactDismiss = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rx.setDelegate(self)
        .disposed(by: disposeBag)
        
        model.asObservable()
        .bind(to: (tableView.rx.items(dataSource: dataSource)))
        .disposed(by: disposeBag)
        
        item.asObservable().subscribe(onNext:{ [unowned self] contact in
            self.titleLabel.text = contact.fullName
            var mode: [SectionModel<String,(label:String,details:String)>] = []
            var phoneNumbers: [(label: String,details: String)] = []
            var address: [(label: String,details: String)] = []
            for (index,label) in contact.phoneNumberLabel.enumerated(){
                phoneNumbers += [(label: label,details: contact.phoneNumber[index])]
            }
            mode += [SectionModel(model: "Phone", items: phoneNumbers)]
            if contact.addressLabel.count != 0{
                for (index,label) in contact.addressLabel.enumerated(){
                    address += [(label: label,details: contact.addressDetails[index])]
                }
                mode += [SectionModel(model: "address", items: address)]
            }
            self.model.accept(mode)
        })
        .disposed(by: disposeBag)
        
        Observable.merge(edit.rx.tap.asObservable(),edit1.rx.tap.asObservable(),edit2.rx.tap.asObservable()).subscribe(onNext: { [weak self]  in
            //self?.navigationController?.setNavigationBarHidden(true, animated: false)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "newContact") as! NewContactViewController
            vc.presentContact = self?.item.value
            self?.definesPresentationContext = true
            vc.modalPresentationStyle = .overCurrentContext
            self?.present(vc, animated: true){
                vc.presentationController?.presentedView?.gestureRecognizers?[0].isEnabled = false
            }
        })
        .disposed(by: disposeBag)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
            return 0.0
        }
        return 40.0
    }
}
