//
//  TripsManager.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 10/22/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit
import CoreData

protocol TripsManagerDelegate: AnyObject {
    func retrievedSampleTrip(_ trip: LedgitTrip)
    func retrievedTrip(_ trip: LedgitTrip)
    func addedTrip(_ trip: LedgitTrip)
}

class TripsManager {
    weak var delegate: TripsManagerDelegate?
    var isConnected: Bool { return Reachability.isConnectedToNetwork }

    var coreData: NSManagedObjectContext {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Application Delegate wasn't found. Something went terribly wrong.")
        }

        return appDelegate.persistentContainer.viewContext
    }
}

extension TripsManager {

    // MARK: - Fetch Sample Trip Method
    func fetchSampleTrip() {
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaultKeys.sampleTrip) == true else {
            LedgitLog.warning("Could not fetch sample trip key from user defaults")
            return
        }

        // NOTE: Not really core data, since you can't hard code data using core-data
        // I'll just add information here.
        let startDate = Date().dateAt(.prevMonth).dateAtStartOf(.month)
        let endDate = Date().dateAt(.nextMonth).dateAtStartOf(.month)
        let tripLength = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 61

        let tripDictionary: NSDictionary = [LedgitTrip.Keys.key: Constants.ProjectID.sample,
                                            LedgitTrip.Keys.name: "Europe \(Date().year)",
            LedgitTrip.Keys.startDate: "\(startDate.toString(style: .full))",
            LedgitTrip.Keys.endDate: "\(endDate.toString(style: .full))",
            LedgitTrip.Keys.currencies: ["USD", "MXN", "EUR"],
            LedgitTrip.Keys.users: "",
            LedgitTrip.Keys.owner: "Ledgit",
            LedgitTrip.Keys.budget: Double(57),
            LedgitTrip.Keys.length: tripLength,
            LedgitTrip.Keys.budgetSelection: "Daily"]

        guard let sampleTrip = LedgitTrip(dict: tripDictionary) else {
            LedgitLog.warning("Was not able to create a sample trip when requested.")
            return
        }
        delegate?.retrievedSampleTrip(sampleTrip)
    }

    // MARK: - Fetch Trip Methods
    func fetchTrips() {
        fetchCoreDataTrip()
    }

    func fetchTrip(with key: String) -> LedgitTrip? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.LedgitEntity.trip)
        request.predicate = NSPredicate(format: "\(LedgitTrip.Keys.key) == %@", key)
        request.fetchLimit = 1

        do {
            let trips = try coreData.fetch(request)

            guard let trip = trips.first as? NSManagedObject else {
                LedgitLog.warning("Could not fetch trips with key: \(key)")
                return nil
            }

            let data: NSDictionary = [
                LedgitTrip.Keys.key: trip.value(forKey: LedgitTrip.Keys.key) as Any,
                LedgitTrip.Keys.name: trip.value(forKey: LedgitTrip.Keys.name) as Any,
                LedgitTrip.Keys.users: trip.value(forKey: LedgitTrip.Keys.users) as Any,
                LedgitTrip.Keys.owner: trip.value(forKey: LedgitTrip.Keys.owner) as Any,
                LedgitTrip.Keys.length: trip.value(forKey: LedgitTrip.Keys.length) as Any,
                LedgitTrip.Keys.endDate: trip.value(forKey: LedgitTrip.Keys.endDate) as Any,
                LedgitTrip.Keys.budget: trip.value(forKey: LedgitTrip.Keys.budget) as Any,
                LedgitTrip.Keys.startDate: trip.value(forKey: LedgitTrip.Keys.startDate) as Any,
                LedgitTrip.Keys.currencies: trip.value(forKey: LedgitTrip.Keys.currencies) as Any,
                LedgitTrip.Keys.budgetSelection: trip.value(forKey: LedgitTrip.Keys.budgetSelection) as Any
            ]

            guard let ledgitTrip = LedgitTrip(dict: data) else {
                LedgitLog.critical("Could not generate Ledgit trip from core data managed object")
                return nil
            }

            return ledgitTrip

        } catch {
            LedgitLog.critical("Something is wrong. Could not get core data trips")
            return nil
        }
    }

    private func fetchCoreDataTrip() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.LedgitEntity.trip)

        do {
            let tripManagedObjects = try coreData.fetch(request)

            guard let trips = tripManagedObjects as? [NSManagedObject] else {
                LedgitLog.warning("Could not fetch trips from coredata even though something was retrieved")
                return
            }

            trips.forEach { trip in
                let data: NSDictionary = [
                    LedgitTrip.Keys.key: trip.value(forKey: LedgitTrip.Keys.key) as Any,
                    LedgitTrip.Keys.name: trip.value(forKey: LedgitTrip.Keys.name) as Any,
                    LedgitTrip.Keys.users: trip.value(forKey: LedgitTrip.Keys.users) as Any,
                    LedgitTrip.Keys.owner: trip.value(forKey: LedgitTrip.Keys.owner) as Any,
                    LedgitTrip.Keys.length: trip.value(forKey: LedgitTrip.Keys.length) as Any,
                    LedgitTrip.Keys.endDate: trip.value(forKey: LedgitTrip.Keys.endDate) as Any,
                    LedgitTrip.Keys.budget: trip.value(forKey: LedgitTrip.Keys.budget) as Any,
                    LedgitTrip.Keys.startDate: trip.value(forKey: LedgitTrip.Keys.startDate) as Any,
                    LedgitTrip.Keys.currencies: trip.value(forKey: LedgitTrip.Keys.currencies) as Any,
                    LedgitTrip.Keys.budgetSelection: trip.value(forKey: LedgitTrip.Keys.budgetSelection) as Any
                ]

                guard let ledgitTrip = LedgitTrip(dict: data) else {
                    LedgitLog.critical("Could not generate Ledgit trip from core data managed object")
                    return
                }

                self.delegate?.retrievedTrip(ledgitTrip)
            }

        } catch {
            LedgitLog.critical("Something is wrong. Could not get core data trips")
        }
    }

    // MARK: - Remove Trip Methods
    func removeTrip(withKey key: String) {
        removeCoreDataTrip(key)
    }

    private func removeCoreDataTrip(_ key: String) {
        let tripRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.LedgitEntity.trip)
        tripRequest.predicate = NSPredicate(format: "\(LedgitTrip.Keys.key) == %@", key)
        tripRequest.fetchLimit = 1

        let entryRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.LedgitEntity.entry)
        entryRequest.predicate = NSPredicate(format: "\(LedgitEntry.Keys.owningTrip) == %@", key)
        entryRequest.fetchLimit = 1

        do {
            let trips = try coreData.fetch(tripRequest)
            let entries = try coreData.fetch(entryRequest)

            guard let trip = trips.first as? NSManagedObject else {
                LedgitLog.warning("Could not fetch trip with key")
                return
            }

            coreData.delete(trip)

            guard let entryManagedObjects = entries as? [NSManagedObject] else {
                LedgitLog.critical("Successfully deleted trip, but could not create managed objects of entries associated with trip")
                return
            }

            entryManagedObjects.forEach { coreData.delete($0) }

            try coreData.save()

        } catch {
            LedgitLog.critical("Something is wrong. Could not get core data trips")
        }
    }

    // MARK: - Create Trip Methods
    func createNew(trip: NSDictionary) {
        createCoreDataTrip(data: trip)
    }

    private func createCoreDataTrip(data: NSDictionary) {
        guard let entity = NSEntityDescription.entity(forEntityName: Constants.LedgitEntity.trip, in: coreData) else {
            LedgitLog.warning("Could not create trip entity")
            return
        }

        let trip = NSManagedObject(entity: entity, insertInto: coreData)

        guard
            let budget = data[LedgitTrip.Keys.budget] as? Double,
            let budgetSelection = data[LedgitTrip.Keys.budgetSelection] as? String,
            let currencies = data[LedgitTrip.Keys.currencies] as? [String],
            let startDate = data[LedgitTrip.Keys.startDate] as? String,
            let endDate = data[LedgitTrip.Keys.endDate] as? String,
            let key = data[LedgitTrip.Keys.key] as? String,
            let length = data[LedgitTrip.Keys.length] as? Int,
            let name = data[LedgitTrip.Keys.name] as? String,
            let owner = data[LedgitTrip.Keys.owner] as? String,
            let users = data[LedgitTrip.Keys.users] as? String
            else {
                LedgitLog.critical("Could not parse through NSDictionary sent by TripActionViewController, so something is wrong")
                return
        }

        trip.setValue(budgetSelection, forKey: LedgitTrip.Keys.budgetSelection)
        trip.setValue(currencies, forKey: LedgitTrip.Keys.currencies)
        trip.setValue(startDate, forKey: LedgitTrip.Keys.startDate)
        trip.setValue(budget, forKey: LedgitTrip.Keys.budget)
        trip.setValue(endDate, forKey: LedgitTrip.Keys.endDate)
        trip.setValue(length, forKey: LedgitTrip.Keys.length)
        trip.setValue(owner, forKey: LedgitTrip.Keys.owner)
        trip.setValue(users, forKey: LedgitTrip.Keys.users)
        trip.setValue(name, forKey: LedgitTrip.Keys.name)
        trip.setValue(key, forKey: LedgitTrip.Keys.key)

        do {
            try coreData.save()

            guard let ledgitTrip = LedgitTrip(dict: data) else {
                LedgitLog.critical("Core data inserted trip data, but no ledgit trip was produced")
                return
            }

            self.delegate?.addedTrip(ledgitTrip)

        } catch let error as NSError {
            LedgitLog.warning("Could not save. \(error), \(error.userInfo)")
        }
    }

    // MARK: - Update Trip Methods
    func update(_ trip: LedgitTrip) {
        updateCoreData(trip)
    }

    private func updateCoreData(_ trip: LedgitTrip) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.LedgitEntity.trip)
        request.predicate = NSPredicate(format: "\(LedgitTrip.Keys.key) == %@", trip.key)
        request.fetchLimit = 1

        do {
            let trips = try coreData.fetch(request)

            guard let tripManagedObject = trips.first as? NSManagedObject else {
                LedgitLog.warning("Could not fetch trip with key")
                return
            }

            tripManagedObject.setValue(trip.budgetSelection.rawValue, forKey: LedgitTrip.Keys.budgetSelection)
            tripManagedObject.setValue(trip.currencies.map { $0.code }, forKey: LedgitTrip.Keys.currencies)
            tripManagedObject.setValue(trip.startDate, forKey: LedgitTrip.Keys.startDate)
            tripManagedObject.setValue(trip.budget, forKey: LedgitTrip.Keys.budget)
            tripManagedObject.setValue(trip.endDate, forKey: LedgitTrip.Keys.endDate)
            tripManagedObject.setValue(trip.length, forKey: LedgitTrip.Keys.length)
            tripManagedObject.setValue(trip.owner, forKey: LedgitTrip.Keys.owner)
            tripManagedObject.setValue(trip.users, forKey: LedgitTrip.Keys.users)
            tripManagedObject.setValue(trip.name, forKey: LedgitTrip.Keys.name)
            tripManagedObject.setValue(trip.key, forKey: LedgitTrip.Keys.key)

            try coreData.save()

        } catch let error as NSError {
            LedgitLog.warning("Could not save. \(error), \(error.userInfo)")
        }
    }
}
