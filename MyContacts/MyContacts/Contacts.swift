//
//  Contacts.swift
//  MyContacts
//
//  Created by Mallikharjuna avula on 08/11/19.
//  Copyright © 2019 Mallikharjuna avula. All rights reserved.
//

import Foundation
import RxDataSources
import RealmSwift
import Contacts

//Mark: model for realm
class myContact: Object{
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var name:String = ""
    @objc dynamic var familyName: String = ""
    @objc dynamic var middleName: String = ""
    @objc dynamic var edit: Bool = false
    @objc dynamic var existed: Bool = true
    dynamic var addressLabel = List<String>()
    dynamic var addressDetails = List<String>()
    dynamic var phoneNumberLabel = List<String>()
    dynamic var phoneNumber = List<String>()
    var fullName: String{
        return "\(name) \(middleName) \(familyName)"
    }
    override class func primaryKey() -> String? {
        return "id"
    }
    convenience init(name: String, fName: String, mName: String) {
        self.init()
        self.name = name
        self.familyName = fName
        self.middleName = mName
    }
    override func isEqual(_ object: Any?) -> Bool {
        if let recieverContact = object as? myContact{
            if id == recieverContact.id && fullName == recieverContact.fullName && addressDetails == recieverContact.addressDetails && phoneNumber == recieverContact.phoneNumber && edit == recieverContact.edit{
                return true
            }
        }
        return false
    }
}

extension myContact{
    //Mark: Init() for type of SectionModel of DetailViewControllers
    convenience init(model: [SectionModel<contactFields,contactCells>]? = nil){
        self.init()
        if let model = model{
            for modl in model{
                for item in modl.items{
                    switch item {
                    case .name(let nameDetails):
                        name = nameDetails[0]
                        middleName = nameDetails[1]
                        familyName = nameDetails[2]
                        break
                    case .numbers(let number):
                            phoneNumber.append(number.details)
                            phoneNumberLabel.append(number.label)
                        break
                    case .address(let address):
                            addressDetails.append(address.details)
                            addressLabel.append(address.label)
                        break
                    default:
                        break
                    }
                }
            }
        }
    }
}

//Mark: Sections for viewController for displaying all contacts
struct sectionsOfContacts{
    let header: String
    var items: [Item]
}

//Mark: items for SectionModel for each contact in NewContactViewController
public enum contactCells{
    case name([String])
    case numbers(label:String,details: String)
    case address(label:String,details: String)
    case delete
}

extension sectionsOfContacts: SectionModelType{
    typealias Item = myContact
    init(original: sectionsOfContacts, items: [myContact]) {
        self = original
        self.items = items
    }
}

enum contactFields{
    case name
    case Phone
    case address
    case add
    case delete
}

