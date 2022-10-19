//
//  AuthenticationManager.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 10/19/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit
import CoreData

typealias ErrorDictionary = [String:String]

protocol AuthenticationManagerDelegate: AnyObject {
    func userAuthenticated(_ user: LedgitUser)
    func authenticationError(_ error: LedgitError)
}

class AuthenticationManager {
    weak var delegate: AuthenticationManagerDelegate?
    var coreData: NSManagedObjectContext {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Application Delegate wasn't found. Something went terribly wrong.")
        }

        return appDelegate.persistentContainer.viewContext
    }

    #if DEBUG
    var isConnected: Bool = false
    #else
    var isConnected: Bool {
        return Reachability.isConnectedToNetwork
    }
    #endif

    init() {
        #if DEBUG
        isConnected = Reachability.isConnectedToNetwork
        #endif
    }
}

extension AuthenticationManager {
    func performCoreDataSignUp() {
        guard let entity = NSEntityDescription.entity(forEntityName: Constants.LedgitEntity.user, in: coreData) else {
            LedgitLog.warning("Could not create user entity")
            return
        }

        let user = NSManagedObject(entity: entity, insertInto: coreData)
        let name = ""
        let email = ""
        let key = UUID().uuidString.lowercased()
        let provider = "Ledgit"
        let subscription = "Free"
        let homeCurrency = "USD"
        let categories = ["Transportation", "Food", "Lodging", "Entertainment", "Emergency", "Miscellaneous"]

        let data: NSDictionary = [
            LedgitUser.Keys.key: key,
            LedgitUser.Keys.email: email,
            LedgitUser.Keys.provider: provider,
            LedgitUser.Keys.categories: categories,
            LedgitUser.Keys.subscription: subscription,
            LedgitUser.Keys.homeCurrency: homeCurrency
        ]

        user.setValue(email, forKey: LedgitUser.Keys.email)
        user.setValue(name, forKey: LedgitUser.Keys.name)
        user.setValue(provider, forKey: LedgitUser.Keys.provider)
        user.setValue(subscription, forKey: LedgitUser.Keys.subscription)
        user.setValue(homeCurrency, forKey: LedgitUser.Keys.homeCurrency)
        user.setValue(key, forKey: LedgitUser.Keys.key)
        user.setValue(categories, forKey: LedgitUser.Keys.categories)

        do {
            try coreData.save()
            UserDefaults.standard.set(key, forKey: Constants.UserDefaultKeys.uid)
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultKeys.sampleTrip)

            let ledgitUser = LedgitUser(dict: data)
            self.delegate?.userAuthenticated(ledgitUser)

        } catch let error as NSError {
            LedgitLog.warning("Could not add user object to core data. \(error), \(error.userInfo)")
            self.delegate?.authenticationError(.coreDataFault)
        }
    }

    func performFirebaseSignIn(with email:String, password: String) {
        guard isConnected else {
            self.delegate?.authenticationError(.noNetworkConnection)
            return
        }

        guard !email.isEmpty, !password.isEmpty else {
            self.delegate?.authenticationError(.emptyTextFields)
            return
        }
    }
}
