//
//  TripsPresenter.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 10/22/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import Foundation

protocol TripsPresenterDelegate: AnyObject {
    func retrievedSampleTrip()
    func retrievedTrip()
    func addedTrip()
}

class TripsPresenter {
    weak var delegate: TripsPresenterDelegate?
    var manager: TripsManager!
    var trips: [LedgitTrip] = []

    init(manager: TripsManager) {
        self.manager = manager
        self.manager.delegate = self
    }

    func retrieveTrips() {
        // Always check to see if sample trip is needed
        manager.fetchSampleTrip()

        // Fetch rest of trips
        manager.fetchTrips()
    }

    func removeTrip(at index: Int) {
        let key = trips[index].key
        trips.remove(at: index)
        manager.removeTrip(withKey: key)
    }

    func createNew(trip dict: NSDictionary) {
        manager.createNew(trip: dict)
    }

    func edited(_ trip: LedgitTrip) {
        manager.update(trip)
    }
}

extension TripsPresenter: TripsManagerDelegate {
    func retrievedSampleTrip(_ trip: LedgitTrip) {
        trips.insert(trip, at: 0)
        delegate?.retrievedSampleTrip()
    }

    func retrievedTrip(_ trip: LedgitTrip) {
        trips.append(trip)
        delegate?.retrievedTrip()
    }

    func addedTrip(_ trip: LedgitTrip) {
        trips.append(trip)
        delegate?.addedTrip()
    }
}
