//
//  AppDelegate.swift
//  MyContacts
//
//  Created by Mallikharjuna avula on 07/11/19.
//  Copyright © 2019 Mallikharjuna avula. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let realm = try! Realm(configuration: Realm.Configuration(schemaVersion: 5,migrationBlock : { migration, oldSchemaVersion in
        if oldSchemaVersion < 1 {
            var nextID = 0
            migration.enumerateObjects(ofType: myContact.className()) { oldObject, newObject in
                newObject!["id"] = "\(nextID)"
                nextID += 1
            }
        }
    }))
    lazy var vm = ViewModel()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

