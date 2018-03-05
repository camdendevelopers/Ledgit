//
//  TripDetailManager.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 11/26/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import Foundation
import Firebase

protocol TripDetailManagerDelegate: class {
    func createdEntry(_ entry: LedgitEntry)
    func retrievedEntry(_ entry: LedgitEntry)
    func removedEntry(_ entry: LedgitEntry)
    func updatedEntry(_ entry: LedgitEntry)
}

class TripDetailManager {
    weak var delegate: TripDetailManagerDelegate?
    let auth = Auth.auth()
    let trips = Database.database().reference().child("trips")
    let entries = Database.database().reference().child("entries")
    
    #if DEBUG
    var isConnected: Bool = false
    #else
    var isConnected: Bool {
        get { return Reachability.isConnectedToNetwork() }
    }
    #endif
    
    init() {
    #if DEBUG
        isConnected = Reachability.isConnectedToNetwork()
    #endif
    }
    
    deinit {
        entries.removeAllObservers()
    }
}

extension TripDetailManager {
    func fetchEntries(forTrip trip: LedgitTrip) {
        entries
            .queryOrdered(byChild: "owningTrip")
            .queryEqual(toValue: trip.key)
            .observeSingleEvent(of: .value) { snapshot in
            guard
                let snapshot = snapshot.value as? NSDictionary,
                let entriesData = snapshot.allValues as? [NSDictionary]
            else { return }
            
            entriesData.forEach {
                guard let entry = LedgitEntry(dict: $0) else { return }
                self.delegate?.retrievedEntry(entry)
            }
        }
    }
    
    func createEntry(with data: NSDictionary) {
        guard let entryKey = data["key"] as? String else { return }
        guard let tripKey = data["owningTrip"] as? String else { return }
        entries.child(entryKey).setValue(data)
        trips.child(tripKey).updateChildValues(["entries": entryKey])
        
        entries.queryOrdered(byChild: "owningTrip").queryEqual(toValue: tripKey).observeSingleEvent(of: .childChanged) { snapshot in
            guard let snapshot = snapshot.value as? NSDictionary else { return }
            guard let entry = LedgitEntry(dict: snapshot) else { return }
            self.delegate?.createdEntry(entry)
        }
    }
    
    func remove(_ entry: LedgitEntry) {
        entries.child(entry.key).removeValue { (error, ref) in
            guard error == nil else { return }
            self.delegate?.removedEntry(entry)
        }
    }
    
    func update(_ entryData: NSDictionary) {
        guard let entry = LedgitEntry(dict: entryData) else { return }
        entries.child(entry.key).setValue(entryData)
        delegate?.updatedEntry(entry)
    }
}
