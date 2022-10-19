//
//  TripsViewController.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 8/15/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit
import AMPopTip

class TripsViewController: UIViewController {
    @IBOutlet weak var tripsTableView: UITableView!
    private let presenter = TripsPresenter(manager: TripsManager())
    private var defaultTripIndexPath: IndexPath?
    private var editingIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupPresenter()
    }

    func setupPresenter() {
        presenter.delegate = self
        presenter.retrieveTrips()
    }

    func setupTableView() {
        tripsTableView.delegate = self
        tripsTableView.dataSource = self
        tripsTableView.rowHeight = UITableView.automaticDimension
        tripsTableView.estimatedRowHeight = 200
        tripsTableView.sectionHeaderHeight = 10
    }

    @IBAction func addTripButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: Constants.SegueIdentifiers.action, sender: nil)
    }

    @IBAction func settingsButtonPressed(_ sender: Any) {
        let navigationController = SettingsNavigationController.instantiate(from: .settings)

        present(navigationController, animated: true, completion: nil)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.SegueIdentifiers.action {
            guard let navigationController = segue.destination as? UINavigationController else { return }
            guard let destinationViewController = navigationController.topViewController as? TripActionViewController else { return }
            destinationViewController.delegate = self
            destinationViewController.presenter = presenter

            if let trip = sender as? LedgitTrip {
                destinationViewController.method = .edit
                destinationViewController.trip = trip
            } else {
                destinationViewController.method = .add
            }

        } else if segue.identifier == Constants.SegueIdentifiers.detail {
            guard let destinationViewController = segue.destination as? TripDetailViewController else { return }
            guard let trip = sender as? LedgitTrip else { return }
            destinationViewController.title = trip.name
            destinationViewController.currentTrip = trip
        }
    }
}

extension TripsViewController: TripActionDelegate {
    func added(trip dict: NSDictionary) {
        presenter.createNew(trip: dict)
    }

    func edited(_ trip: LedgitTrip) {
        guard let index = presenter.trips.firstIndex(where: { $0.key == trip.key }) else { return }
        presenter.edited(trip)

        presenter.trips.remove(at: index)
        presenter.trips.insert(trip, at: index)

        guard let path = editingIndexPath else { return }
        tripsTableView.reloadRows(at: [path], with: .fade)
        editingIndexPath = nil
    }
}

extension TripsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return presenter.trips.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifiers.trip, for: indexPath) as! TripTableViewCell // swiftlint:disable:this force_cast
        let trip = presenter.trips[indexPath.section]
        cell.configure(with: trip, at: indexPath)

        if trip.key == UserDefaults.standard.value(forKey: Constants.UserDefaultKeys.defaultTrip) as? String && editingIndexPath == nil {
            self.tableView(tripsTableView, didSelectRowAt: indexPath)
        }

        // We are going to display a pop tip if the trip is a sample one
        if trip.key == Constants.ProjectID.sample && !UserDefaults.standard.bool(forKey: Constants.UserDefaultKeys.hasShownSampleTripTip) {
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultKeys.hasShownSampleTripTip)
            let popTip = PopTip()
            popTip.style(PopStyle.default)
            popTip.shouldDismissOnTap = true
            popTip.show(text: "Check out this sample trip. Swipe left to remove.",
                        direction: .down, maxWidth: 300,
                        in: view, from: cell.frame, duration: 3)
        }

        return cell
    }
}

extension TripsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrip = presenter.trips[indexPath.section]

        performSegue(withIdentifier: Constants.SegueIdentifiers.detail, sender: selectedTrip)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let selectedSection = indexPath.section
        let trip = presenter.trips[selectedSection]

        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { _ in
                self.editingIndexPath = indexPath
                self.performSegue(withIdentifier: Constants.SegueIdentifiers.action, sender: trip)
            }

            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                let alert = UIAlertController(title: "Warning", message: "Are you sure you want to delete this trip?", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in

                    if selectedSection == 0 && UserDefaults.standard.bool(forKey: Constants.UserDefaultKeys.sampleTrip) {
                        UserDefaults.standard.set(false, forKey: Constants.UserDefaultKeys.sampleTrip)
                    }

                    tableView.beginUpdates()
                    self.presenter.removeTrip(at: selectedSection)
                    tableView.deleteSections([selectedSection], with: .fade)

                    tableView.endUpdates()

                }

                alert.addAction(cancelAction)
                alert.addAction(deleteAction)

                self.present(alert, animated: true, completion: nil)
            }

            let showDeleteOnly = selectedSection == 0 && UserDefaults.standard.bool(forKey: Constants.UserDefaultKeys.sampleTrip)
            let actions = showDeleteOnly ? [delete] : [edit, delete]

            return UIMenu(title: "Trip Options", children: actions)
        }
        return configuration
    }
}

extension TripsViewController: TripsPresenterDelegate {
    func retrievedSampleTrip() {
        tripsTableView.beginUpdates()
        tripsTableView.insertSections([0], with: .right)
        tripsTableView.endUpdates()
    }

    func retrievedTrip() {
        tripsTableView.beginUpdates()
        tripsTableView.insertSections([presenter.trips.count], with: .right)
        tripsTableView.endUpdates()
    }

    func addedTrip() {
        tripsTableView.reloadData()
    }
}
