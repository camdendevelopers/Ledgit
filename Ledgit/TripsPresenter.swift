//
//  TripsPresenter.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 10/22/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import Foundation

protocol TripsPresenterDelegate: class {
    func retrievedSampleTrip()
    func retrievedTrip()
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
        guard let currentUserKey = UserDefaults.standard.value(forKey: Constants.userDefaultKeys.uid) as? String else {
            return
        }
        
        AuthenticationManager.shared.users.child(currentUserKey).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.value as? NSDictionary else { return }
            LedgitUser.current = LedgitUser(dict: snapshot)
            self.manager.fetchSampleTrip()
            self.manager.fetchTrip()
        })
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

extension TripsPresenter: TripsManagerDelegate{
    func retrievedSampleTrip(_ trip: LedgitTrip) {
        trips.insert(trip, at: 0)
        delegate?.retrievedSampleTrip()
    }
    
    func retrievedTrip(_ trip: LedgitTrip) {
        trips.append(trip)
        delegate?.retrievedTrip()
    }
    
    func addedTrip() {
        
    }
}
