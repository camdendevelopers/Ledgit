//
//  TripDetailPresenter.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 11/26/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import Foundation

protocol TripDetailPresenterDelegate: AnyObject {
    func receivedEntryUpdate()
}

class TripDetailPresenter {
    weak var delegate: TripDetailPresenterDelegate?
    var manager: TripDetailManager!
    var trip: LedgitTrip!
    var entries: [LedgitEntry] = []
    var costToday: Double = 0
    var totalCost: Double = 0
    var averageCost: Double = 0
    var dates: [Date] = []

    init(manager: TripDetailManager) {
        self.manager = manager
        self.manager.delegate = self
    }

    func attach(_ trip: LedgitTrip) {
        self.trip = trip
    }

    func create(entry: NSDictionary) {
        manager.createEntry(with: entry)
    }

    func update(entry: NSDictionary) {
        manager.update(entry)
    }

    func fetchEntries() {
        manager.fetchEntries(forTrip: trip)
    }

    func remove(_ entry: LedgitEntry) {
        manager.remove(entry)
    }
}

extension TripDetailPresenter: TripDetailManagerDelegate {
    func createdEntry(_ entry: LedgitEntry) {
        entries.append(entry)
        delegate?.receivedEntryUpdate()
    }

    func updatedEntry(_ entry: LedgitEntry) {
        guard let index = entries.firstIndex(where: {$0.key == entry.key}) else { return }
        entries.remove(at: index)
        entries.insert(entry, at: index)
        delegate?.receivedEntryUpdate()
    }

    func removedEntry(_ entry: LedgitEntry) {
        guard let index = entries.firstIndex(where: { $0.key == entry.key }) else { return }
        entries.remove(at: index)
        delegate?.receivedEntryUpdate()
    }

    func retrievedEntry(_ entry: LedgitEntry) {
        entries.append(entry)
        delegate?.receivedEntryUpdate()
    }

    func retrievedSampleEntries(_ entries: [LedgitEntry]) {
        self.entries = entries
        delegate?.receivedEntryUpdate()
    }
}
