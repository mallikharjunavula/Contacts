//
//  ViewController.swift
//  MyContacts
//
//  Created by Mallikharjuna avula on 07/11/19.
//  Copyright © 2019 Mallikharjuna avula. All rights reserved.
//

import UIKit
import Contacts
import RxSwift
import RealmSwift
import RxDataSources
import RxRelay

class ViewController: UIViewController, UISplitViewControllerDelegate {
    
    @IBOutlet weak var newContact: UIButton!
    //Mark:load the contacts for first time
    var loadContacts = true
    //Mark: specify it is a deleted and reload the view in compact height and compact width
    var deleted = false
    //Mark:to laod the first contact in the DetailViewController
    var first = true
    @IBOutlet weak var tableView: UITableView!
    var token: NotificationToken? = nil
    let disposeBag = DisposeBag()
    let realm = (UIApplication.shared.delegate as! AppDelegate).realm
    let vm = (UIApplication.shared.delegate as! AppDelegate).vm
    
    lazy var dataSource = RxTableViewSectionedReloadDataSource<sectionsOfContacts>(configureCell: {dataSource, table, indexPath, item in
            if indexPath.row == 0 && indexPath.section == 0 && (self.first || self.deleted){
                let vc = self.splitViewController?.viewControllers.last as? DetailContactViewController
                var x: [myContact]
                self.first = false
                self.deleted = false
                x = Array(self.realm.objects(myContact.self).sorted(byKeyPath: "name").filter("existed = true"))
                vc?.item.accept(x[0])
            }
            
            let cell = table.dequeueReusableCell(withIdentifier: "cell",for: indexPath)
            if let newCell = cell as? TableViewCell{
                newCell.textLabel?.text = "\(item.fullName)"
                newCell.item = item
            }
            return cell
    })
    
//    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
//        return true
//    }
    
    override func awakeFromNib() {
        splitViewController?.delegate = self
        splitViewController?.preferredDisplayMode = .allVisible
    }
    
    override func viewDidAppear(_ animated: Bool) {
       
        first = true
        let contacts = realm.objects(myContact.self)
        super.viewDidAppear(animated)
        token = contacts.observe {[unowned self] (change) in
            switch change{
            case .update(let results,_,let ins,let mod):
                for insertion in ins{
                    let contact = contacts[insertion]
                    self.vm.sections.append(String(contact.name.prefix(1).uppercased()), contact)
                }
                for modification in mod{
                    let contact = results[modification]
                    if contact.existed == false{
                        self.vm.sections.delete(contact,"delete")
                        self.deleted = true
                    }
                    else{
                        self.vm.sections.delete(contact,"modify")
                    }
                }
                break
            case .initial(let contacts):
                if self.loadContacts{
                   self.vm.loadContacts()
                    let resultContacts = contacts.sorted(byKeyPath: "name")
                    for contact in resultContacts{
                        self.vm.sections.append(String(contact.name.prefix(1).uppercased()), contact)
                    }
                    self.loadContacts = false
                }
                if self.first{
                    let resultContacts = contacts.sorted(byKeyPath: "name")
                    for contact in resultContacts{
                        if contact.existed == false{
                            self.vm.sections.delete(contact,"delete")
                            self.deleted = true
                        }
                    }
                }
                break
            case .error(let i):
                print(i)
                break
            }
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource.titleForHeaderInSection = {dataSource,index in
            return dataSource.sectionModels[index].header
        }
        
        vm
        .sections
        .asObservable()
        .bind(to: tableView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
        .do(onNext: { [unowned self] indexPath in
            self.tableView.deselectRow(at: indexPath, animated: false)
        })
        .subscribe(onNext: { [weak self] index in
            let cell = self?.tableView.cellForRow(at: index)
            self?.performSegue(withIdentifier: "ViewContact", sender: cell)
        })
        .disposed(by: disposeBag)
        
        newContact.rx.tap.subscribe(onNext:{ [unowned self] in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "newContact")
            self.present(vc, animated: true)
        })
        .disposed(by: disposeBag)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?)-> Bool {
        guard identifier == "ViewContact" else{
            return false
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVc  = segue.destination as? DetailContactViewController,let cell = sender as? TableViewCell{
            destinationVc.item.accept(cell.item ?? myContact())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if token != nil{
            token?.invalidate()
        }
    }
}
