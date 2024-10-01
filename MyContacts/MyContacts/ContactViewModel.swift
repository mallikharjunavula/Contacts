//
//  ContactsViewModel.swift
//  MyContacts
//
//  Created by Mallikharjuna avula on 08/11/19.
//  Copyright © 2019 Mallikharjuna avula. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Contacts
import RxRelay
import RxDataSources
import ContactsUI

class ViewModel{
    let sections = BehaviorRelay<[sectionsOfContacts]>(value: [])
    let realm = (UIApplication.shared.delegate as! AppDelegate).realm
    var loadContact: Bool = true
    var first: Bool = true
    let dContact = BehaviorSubject<myContact>(value: myContact())
    let disposeBag = DisposeBag()
    //MARK: load contacts from contactsStore
    func loadContacts(){
        let store = CNContactStore()
        var contacts = [CNContact]()
        let keys = [CNContactPostalAddressesKey,CNContactFormatter.descriptorForRequiredKeys(for: .fullName),CNContactPhoneNumbersKey] as [Any]
        let requst = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        
        try? store.enumerateContacts(with: requst){ new, stop in
            contacts.append(new)
        }
        
        //MARK:Formatting and storing contacts
        for contact in contacts{
            let mContact = myContact(name: contact.givenName, fName: contact.familyName, mName: contact.middleName)
            mContact.id = contact.identifier
            for number in contact.phoneNumbers{
                if (number.label != nil){
                    var label = number.label!
                    label = String(String(label.dropFirst(4)).dropLast(4))
                    mContact.phoneNumberLabel.append(label)
                    mContact.phoneNumber.append(number.value.stringValue)
                }
            }
            for address in contact.postalAddresses{
                if (address.label != nil){
                    var label = address.label!
                    label = String(String(label.dropFirst(4)).dropLast(4))
                    mContact.addressLabel.append("\(label)address")
                    mContact.addressDetails.append(CNPostalAddressFormatter.string(from: address.value, style: .mailingAddress))
                }
            }
            //MARK:compare the existing realm with contactsStore
            try! realm.write {
                let result = realm.objects(myContact.self).filter("id == '\(contact.identifier)'").first
                if let newContact = result{
                    if newContact != mContact && newContact.edit == false && newContact.existed == true{
                        realm.add(mContact,update: .modified)
                    }
                }
                else{
                    realm.add(mContact)
                }
            }
        }
    }
    
    //MARK:delete conctact
    func deleteContact(_ deleteContact: myContact){
        try! realm.write {
            if let con = realm.objects(myContact.self).filter("id = '\(deleteContact.id)'").first{
                //MARK: adding a bool value that it is deleted
                con.existed = false
            }
        }
    }
    
    //MARK:save a new or existing contact
    func saveConatacts(old: myContact? = nil,new: [SectionModel<String,contactCells>]){
        let newContact = myContact(model: new)
        guard let oldContact = old else {
            try! realm.write{
                realm.add(newContact)
            }
            return
        }
        newContact.id = oldContact.id
        newContact.edit = true
        try! realm.write {
            realm.add(newContact, update: .modified)
        }
    }
}

//MARK: extension for BehaviorRelay<sectionOfContacts> used for appending and deleting the contacts
extension BehaviorRelay where Element == [sectionsOfContacts] {
    func append(_ character: String,_ contact: myContact){
        var newValue = value
        var present: Bool = false
        
        for (index,section) in newValue.enumerated(){
            if character == section.header{
                present = true
                newValue[index].items += [contact]
            }
        }
        if present == false{
            newValue += [sectionsOfContacts(header: character, items: [contact])]
        }
        accept(newValue)
    }
    func delete(_ contact: myContact,_ type: String){
        var newValue = value
        var noContact: Int?
        let model = String(contact.name.prefix(1).uppercased())
        for (sectionIndex,section) in newValue.enumerated(){
            if section.header == model{
                for (index,oldContact) in section.items.enumerated(){
                    if oldContact.id == contact.id{
                        if type == "delete"{
                            newValue[sectionIndex].items.remove(at: index)
                        }
                        else{
                            newValue[sectionIndex].items[index] = contact
                        }
                    }
                }
                if newValue[sectionIndex].items.count == 0{
                    noContact = sectionIndex
                }
            }
        }
        if let index = noContact{
            newValue.remove(at: index)
        }
        accept(newValue)
    }
}

//MARK: extension for BehaviorRealy<sectionModel<String,contactCells>> used for appending and deleting a specific contact for detailViewController
extension BehaviorRelay where Element == [SectionModel<String,contactCells>]{
    func append(_ model: String,_ label: String,_ details: String){
        var newValue = value
        var present: Bool = false
        for (index,section) in newValue.enumerated(){
            if model == section.model{
                present = true
                if model == "address"{
                    newValue[index].items.insert(contactCells.address(label:label,details: details), at: newValue[index].items.count-1)
                }
                else{
                    newValue[index].items.insert(contactCells.numbers(label:label,details: details), at: newValue[index].items.count-1)
                }
            }
        }
        if present == false{
            var modelName = "Phone"
            if label.contains("address"){
                modelName = "address"
            }
            newValue += [SectionModel(model: modelName, items: [contactCells.numbers(label: label,details: details)])]
        }
        accept(newValue)
    }
    func append(_ model: String,_ name: String,_ mName: String,_ fName: String){
        var newValue = value
        for (index,section) in newValue.enumerated(){
            if model == section.model{
                newValue[index].items = [contactCells.name([name,mName,fName])]
            }
        }
        accept(newValue)
    }
    func delete(_ label: String,_ model: String){
        var newValue = value
        for (index,section) in newValue.enumerated(){
            if section.model == model{
                for (itemIndex,item) in newValue[index].items.enumerated(){
                    switch item {
                    case .address(let address):
                        if address.label == label{
                            newValue[index].items.remove(at: itemIndex)
                        }
                        break
                    case .numbers(let phoneNumber):
                        if phoneNumber.label == label{
                            newValue[index].items.remove(at: itemIndex)
                        }
                        break
                    default:
                        break
                    }
                }
            }
        }
        accept(newValue)
    }
    
    func modify(_ label: String,_ change: String){
        var newValue = value
        for (index,section) in newValue.enumerated(){
            for (cellIndex,cell) in section.items.enumerated(){
                switch cell{
                case .name(let name):
                    if label == "FullName" || label == "MiddleName" || label == "FamilyName"{
                        newValue[index].items.remove(at: cellIndex)
                    }
                    switch label {
                    case "FullName":
                        if name.count != 0{
                            newValue[index].items = [contactCells.name([change,name[1],name[2]])]
                        }else{
                            newValue[index].items = [contactCells.name([change,"",""])]
                        }
                        break
                    case "MiddleName":
                        if name.count != 0{
                            newValue[index].items = [contactCells.name([name[0],change,name[2]])]
                        }
                        else{
                            newValue[index].items = [contactCells.name(["",change,""])]
                        }
                        break
                    case "FamilyName":
                        if name.count != 0{
                            newValue[index].items = [contactCells.name([name[0],name[1],change])]
                        }
                        else{
                            newValue[index].items = [contactCells.name(["","",change])]
                        }
                        break
                    default:
                        break
                    }
                    break
                case .numbers(let number):
                    if label == number.label {
                        newValue[index].items.remove(at: cellIndex)
                        newValue[index].items.insert(contactCells.numbers(label: label, details: change), at: cellIndex)
                    }
                    break
                case .address(let addressLabel, _):
                    if label == addressLabel{
                        newValue[index].items.remove(at: cellIndex)
                        newValue[index].items.insert(contactCells.address(label: label, details: change), at: cellIndex)
                    }
                    break
                default: break
                }
            }
        }
        accept(newValue)
    }
}

