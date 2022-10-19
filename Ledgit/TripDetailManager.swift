//
//  TripDetailManager.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 11/26/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit
import CoreData

protocol TripDetailManagerDelegate: AnyObject {
    func retrievedSampleEntries(_ entries: [LedgitEntry])
    func createdEntry(_ entry: LedgitEntry)
    func retrievedEntry(_ entry: LedgitEntry)
    func removedEntry(_ entry: LedgitEntry)
    func updatedEntry(_ entry: LedgitEntry)
}

class TripDetailManager {
    weak var delegate: TripDetailManagerDelegate?

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

extension TripDetailManager {

    // MARK: - Fetch Entry Methods
    func fetchEntries(forTrip trip: LedgitTrip) {
        if trip.key == Constants.ProjectID.sample {
            fetchSampleTripEntries()
        } else {
            fetchCoreDataEntries(for: trip)
        }
    }

    func fetchSampleTripEntries() {
        var sampleEntries: [LedgitEntry] = []

        sampleTripEntries.forEach { dictionary in
            if let entry = LedgitEntry(dict: dictionary) {
                sampleEntries.append(entry)
            }
        }
        delegate?.retrievedSampleEntries(sampleEntries)
    }

    func fetchCoreDataEntries(for trip: LedgitTrip) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.LedgitEntity.entry)
        request.predicate = NSPredicate(format: "\(LedgitEntry.Keys.owningTrip) == %@", trip.key)

        do {
            let entryManagedObjects = try coreData.fetch(request)

            guard let entries = entryManagedObjects as? [NSManagedObject] else {
                LedgitLog.warning("Could not fetch entries from coredata even though something was retrieved")
                return
            }

            entries.forEach { entry in
                let data: NSDictionary = [
                    LedgitEntry.Keys.key: entry.value(forKey: LedgitEntry.Keys.key) as Any,
                    LedgitEntry.Keys.date: entry.value(forKey: LedgitEntry.Keys.date) as Any,
                    LedgitEntry.Keys.currency: entry.value(forKey: LedgitEntry.Keys.currency) as Any,
                    LedgitEntry.Keys.location: entry.value(forKey: LedgitEntry.Keys.location) as Any,
                    LedgitEntry.Keys.description: entry.value(forKey: LedgitEntry.Keys.description) as Any,
                    LedgitEntry.Keys.category: entry.value(forKey: LedgitEntry.Keys.category) as Any,
                    LedgitEntry.Keys.paidBy: entry.value(forKey: LedgitEntry.Keys.paidBy) as Any,
                    LedgitEntry.Keys.paymentType: entry.value(forKey: LedgitEntry.Keys.paymentType) as Any,
                    LedgitEntry.Keys.owningTrip: entry.value(forKey: LedgitEntry.Keys.owningTrip) as Any,
                    LedgitEntry.Keys.cost: entry.value(forKey: LedgitEntry.Keys.cost) as Any,
                    LedgitEntry.Keys.convertedCost: entry.value(forKey: LedgitEntry.Keys.convertedCost) as Any,
                    LedgitEntry.Keys.exchangeRate: entry.value(forKey: LedgitEntry.Keys.exchangeRate) as Any,
                    LedgitEntry.Keys.homeCurrency: entry.value(forKey: LedgitEntry.Keys.homeCurrency) as Any
                ]

                guard let ledgitEntry = LedgitEntry(dict: data) else {
                    LedgitLog.critical("Could not generate Ledgit entry from core data managed object")
                    return
                }

                self.delegate?.retrievedEntry(ledgitEntry)
            }

        } catch {
            LedgitLog.critical("Something is wrong. Could not get core data trips")
        }
    }

    // MARK: - Create Entry Methods
    func createEntry(with data: NSDictionary) {
        createCoreDataEntry(with: data)
    }

    func createCoreDataEntry(with data: NSDictionary) {
        guard let entity = NSEntityDescription.entity(forEntityName: Constants.LedgitEntity.entry, in: coreData) else {
            LedgitLog.warning("Could not create entry entity")
            return
        }

        let entry = NSManagedObject(entity: entity, insertInto: coreData)

        guard let keyString = data[LedgitEntry.Keys.key] as? String,
            let dateString = data[LedgitEntry.Keys.date] as? String,
            let descriptionString = data[LedgitEntry.Keys.description] as? String,
            let currencyString = data[LedgitEntry.Keys.currency] as? String,
            let homeCurrencyString = data[LedgitEntry.Keys.homeCurrency] as? String,
            let locationString = data[LedgitEntry.Keys.location] as? String,
            let categoryString = data[LedgitEntry.Keys.category] as? String,
            let paidByString = data[LedgitEntry.Keys.paidBy] as? String,
            let paymentTypeString = data[LedgitEntry.Keys.paymentType] as? String,
            let owningTripString = data[LedgitEntry.Keys.owningTrip] as? String,
            let costDouble = data[LedgitEntry.Keys.cost] as? Double,
            let convertedCostDouble = data[LedgitEntry.Keys.convertedCost] as? Double,
            let exchangeRateDouble = data[LedgitEntry.Keys.exchangeRate] as? Double else {
                LedgitLog.critical("Could not parse through NSDictionary sent by EntryActionViewController, so something is wrong")
                return
        }

        entry.setValue(keyString, forKey: LedgitEntry.Keys.key)
        entry.setValue(dateString, forKey: LedgitEntry.Keys.date)
        entry.setValue(descriptionString, forKey: LedgitEntry.Keys.description)
        entry.setValue(currencyString, forKey: LedgitEntry.Keys.currency)
        entry.setValue(homeCurrencyString, forKey: LedgitEntry.Keys.homeCurrency)
        entry.setValue(locationString, forKey: LedgitEntry.Keys.location)
        entry.setValue(categoryString, forKey: LedgitEntry.Keys.category)
        entry.setValue(paidByString, forKey: LedgitEntry.Keys.paidBy)
        entry.setValue(paymentTypeString, forKey: LedgitEntry.Keys.paymentType)
        entry.setValue(owningTripString, forKey: LedgitEntry.Keys.owningTrip)
        entry.setValue(costDouble, forKey: LedgitEntry.Keys.cost)
        entry.setValue(convertedCostDouble, forKey: LedgitEntry.Keys.convertedCost)
        entry.setValue(exchangeRateDouble, forKey: LedgitEntry.Keys.exchangeRate)

        do {
            try coreData.save()

            guard let ledgitEntry = LedgitEntry(dict: data) else {
                LedgitLog.critical("Core data inserted trip data, but no ledgit trip was produced")
                return
            }

            self.delegate?.createdEntry(ledgitEntry)
        } catch let error as NSError {
            LedgitLog.warning("Could not save. \(error), \(error.userInfo)")
        }
    }

    // MARK: - Remove Entry Methods
    func remove(_ entry: LedgitEntry) {
        removeCoreData(entry: entry)
    }

    func removeCoreData(entry: LedgitEntry) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.LedgitEntity.entry)
        request.predicate = NSPredicate(format: "\(LedgitEntry.Keys.key) == %@", entry.key)
        request.fetchLimit = 1

        do {
            let entries = try coreData.fetch(request)

            guard let entryManagedObject = entries.first as? NSManagedObject else {
                LedgitLog.warning("Could not fetch trip with key")
                return
            }

            coreData.delete(entryManagedObject)

            try coreData.save()

            self.delegate?.removedEntry(entry)

        } catch {
            LedgitLog.critical("Something is wrong. Could not get core data trips")
        }
    }

    // MARK: - Update Entry Methods
    func update(_ entryData: NSDictionary) {
        updateCoreData(entryData)
    }

    func updateCoreData(_ entryData: NSDictionary) {
        guard let entry = LedgitEntry(dict: entryData) else {
            return
        }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.LedgitEntity.entry)
        request.predicate = NSPredicate(format: "\(LedgitEntry.Keys.key) == %@", entry.key)
        request.fetchLimit = 1

        do {
            let entries = try coreData.fetch(request)

            guard let entryManagedObject = entries.first as? NSManagedObject else {
                LedgitLog.warning("Could not fetch trip with key")
                return
            }

            guard let keyString = entryData[LedgitEntry.Keys.key] as? String,
                let dateString = entryData[LedgitEntry.Keys.date] as? String,
                let descriptionString = entryData[LedgitEntry.Keys.description] as? String,
                let currencyString = entryData[LedgitEntry.Keys.currency] as? String,
                let homeCurrencyString = entryData[LedgitEntry.Keys.homeCurrency] as? String,
                let locationString = entryData[LedgitEntry.Keys.location] as? String,
                let categoryString = entryData[LedgitEntry.Keys.category] as? String,
                let paidByString = entryData[LedgitEntry.Keys.paidBy] as? String,
                let paymentTypeString = entryData[LedgitEntry.Keys.paymentType] as? String,
                let owningTripString = entryData[LedgitEntry.Keys.owningTrip] as? String,
                let costDouble = entryData[LedgitEntry.Keys.cost] as? Double,
                let convertedCostDouble = entryData[LedgitEntry.Keys.convertedCost] as? Double,
                let exchangeRateDouble = entryData[LedgitEntry.Keys.exchangeRate] as? Double else {
                    LedgitLog.critical("Could not parse through NSDictionary sent by EntryActionViewController, so something is wrong")
                    return
            }

            entryManagedObject.setValue(keyString, forKey: LedgitEntry.Keys.key)
            entryManagedObject.setValue(dateString, forKey: LedgitEntry.Keys.date)
            entryManagedObject.setValue(descriptionString, forKey: LedgitEntry.Keys.description)
            entryManagedObject.setValue(currencyString, forKey: LedgitEntry.Keys.currency)
            entryManagedObject.setValue(homeCurrencyString, forKey: LedgitEntry.Keys.homeCurrency)
            entryManagedObject.setValue(locationString, forKey: LedgitEntry.Keys.location)
            entryManagedObject.setValue(categoryString, forKey: LedgitEntry.Keys.category)
            entryManagedObject.setValue(paidByString, forKey: LedgitEntry.Keys.paidBy)
            entryManagedObject.setValue(paymentTypeString, forKey: LedgitEntry.Keys.paymentType)
            entryManagedObject.setValue(owningTripString, forKey: LedgitEntry.Keys.owningTrip)
            entryManagedObject.setValue(costDouble, forKey: LedgitEntry.Keys.cost)
            entryManagedObject.setValue(convertedCostDouble, forKey: LedgitEntry.Keys.convertedCost)
            entryManagedObject.setValue(exchangeRateDouble, forKey: LedgitEntry.Keys.exchangeRate)

            try coreData.save()

            self.delegate?.updatedEntry(entry)

        } catch let error as NSError {

            LedgitLog.warning("Could not save. \(error), \(error.userInfo)")
        }
    }
}
