//
//  TripSelectionTableViewController.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 8/24/19.
//  Copyright © 2019 Camden Developers. All rights reserved.
//

import UIKit

protocol TripSelectionDelegate: AnyObject {
    func selected(_ trip: LedgitTrip)
}

class TripSelectionTableViewController: UITableViewController, TripsManagerDelegate {
    let manager = TripsManager()
    var trips: [LedgitTrip] = []
    weak var delegate: TripSelectionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        manager.fetchTrips()
    }

    @IBAction func doneButtonPressed() {
        dismiss(animated: true)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trips.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell", for: indexPath)
        let trip = trips[indexPath.row]
        cell.textLabel?.text = trip.name

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trip = trips[indexPath.row]

        delegate?.selected(trip)
        doneButtonPressed()
    }

    func retrievedSampleTrip(_ trip: LedgitTrip) {
        // Not expecting to fetch sample trips here
    }

    func retrievedTrip(_ trip: LedgitTrip) {

        tableView.performBatchUpdates({
            self.trips.append(trip)
            self.tableView.insertRows(at: [IndexPath(row: trips.count - 1, section: 0)], with: .bottom)
        }, completion: nil)
    }

    func addedTrip(_ trip: LedgitTrip) {
        // Not expecting to add trips here
    }
}
