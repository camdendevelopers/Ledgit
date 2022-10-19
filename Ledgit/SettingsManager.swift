//
//  SettingsManager.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 11/21/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit
import CoreData

protocol SettingsManagerDelegate: AnyObject {
    func signedout(_ result: SignoutResult)
    func retrieved(_ categories: [String])
    func added(_ category: String)
    func updated(_ categories: [String])
}

class SettingsManager {
    weak var delegate: SettingsManagerDelegate?

    var coreData: NSManagedObjectContext {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Application Delegate wasn't found. Something went terribly wrong.")
        }

        return appDelegate.persistentContainer.viewContext
    }

    var user: NSManagedObject? {
        guard let uid = UserDefaults.standard.value(forKey: Constants.UserDefaultKeys.uid) as? String else {
            return nil
        }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.LedgitEntity.user)
        request.predicate = NSPredicate(format: "\(Constants.UserDefaultKeys.uid) == %@", uid)
        request.fetchLimit = 1

        guard let users = try? coreData.fetch(request) else {
            return nil
        }

        guard let user = users.first as? NSManagedObject else {
            return nil
        }

        return user
    }
}

extension SettingsManager {
    func signout() {
        UserDefaults.standard.set(nil, forKey: Constants.UserDefaultKeys.uid)

        delegate?.signedout(.success)
    }

    func fetchCategories() {
        delegate?.retrieved(LedgitUser.current.categories)
    }

    func add(category: String) {
        // Save categories to core data user

        do {
            LedgitUser.current.categories.append(category)

            user?.setValue(LedgitUser.current.categories, forKey: LedgitUser.Keys.categories)

            try coreData.save()

            delegate?.added(category)

        } catch let error as NSError {
            LedgitLog.critical("Problem saving categories to user \(error)")
        }
    }

    func updateCategory(to newCategory: String, from category: String) {
        var categories = LedgitUser.current.categories

        guard let index = categories.firstIndex(of: category) else { return }

        categories[index] = newCategory

        do {
            try coreData.save()

            LedgitUser.current.categories = categories

            delegate?.updated(categories)

        } catch let error as NSError {
            LedgitLog.error(error)
        }
    }

    func remove(_ category: String) {
        guard let index = LedgitUser.current.categories.firstIndex(of: category) else { return }

        do {
            user?.setValue(LedgitUser.current.categories, forKey: LedgitUser.Keys.categories)

            try coreData.save()

            LedgitUser.current.categories.remove(at: index)

        } catch let error as NSError {
            LedgitLog.error(error)

        }
    }

    func updateUser(name: String, email: String) {
        user?.setValue(email, forKey: LedgitUser.Keys.email)
        user?.setValue(name, forKey: LedgitUser.Keys.name)

        do {
            try coreData.save()
            LedgitUser.current.name = name
            LedgitUser.current.email = email

        } catch let error as NSError {
            LedgitLog.error(error)
        }
    }

    func updateUserHomeCurrency(with currency: LedgitCurrency) {
        // Update each entry to reflect updated home currency
        let entryRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.LedgitEntity.entry)

        LedgitLog.info("Starting currency exchange function")
        do {
            let entries = try coreData.fetch(entryRequest)
            guard let entryManagedObjects = entries as? [NSManagedObject] else {
                LedgitLog.critical("Could not create entry managed objects")
                return
            }

            entryManagedObjects.forEach { entry in
                guard let entryCurrencyCode = entry.value(forKey: LedgitEntry.Keys.currency) as? String,
                    let cost = entry.value(forKey: LedgitEntry.Keys.cost) as? Double else {
                        return
                }

                entry.setValue(currency.code, forKey: LedgitEntry.Keys.homeCurrency)

                // If rates contains the updated currency rate, just use that
                // rather than making a brand new rate fetch
                let currencyKey = currency.code + "_" + entryCurrencyCode
                let defaults = UserDefaults.standard

                if let previouslyFetchedRated = defaults.value(forKey: currencyKey) as? Double {
                    LedgitLog.info("While updating home currency, we found previously fetched rate of \(previouslyFetchedRated)")
                    let newConvertedCost = Double(cost / previouslyFetchedRated)
                    entry.setValue(newConvertedCost, forKey: LedgitEntry.Keys.convertedCost)

                } else {
                    LedgitCurrency.getRate(between: currency.code, and: entryCurrencyCode) { result in
                        switch result {
                        case .success(let rate):
                            // Update our rates dictionary with the newly fetch rate
                            defaults.set(rate, forKey: currencyKey)

                            let newConvertedCost = Double(cost / rate)
                            entry.setValue(newConvertedCost, forKey: LedgitEntry.Keys.convertedCost)

                            LedgitLog.info("Successfully update costs with new rate, trying to save to core data")
                            try? self.coreData.save()
                            LedgitUser.current.homeCurrency = currency
                            self.user?.setValue(currency.code, forKey: LedgitUser.Keys.homeCurrency)

                        case .failure(let error):
                            LedgitLog.critical("Something went wrong when updating conversion cost \(error.localizedDescription)")
                        }
                    }
                }
            }

        } catch let error as NSError {
            LedgitLog.error(error)
        }
    }
}
