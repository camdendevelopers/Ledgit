//
//  CategorySelectionViewController.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 11/26/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit

protocol CategorySelectionDelegate: AnyObject {
    func selected(_ category: String)
}

class CategorySelectionViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private let searchController = UISearchController(searchResultsController: nil)
    weak var delegate: CategorySelectionDelegate?
    lazy var filteredCategories: [String] = []
    var categories: [String] {
        return LedgitUser.current.categories
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        setupTableView()
    }

    func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    @objc func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
}

extension CategorySelectionViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        filteredCategories = categories.filter {
            $0.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
}

extension CategorySelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return !filteredCategories.isEmpty ? filteredCategories.count : categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategorySelectionCell", for: indexPath)
        let category = !filteredCategories.isEmpty ? filteredCategories[indexPath.row] : categories[indexPath.row]

        cell.textLabel?.text(category)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let category = !filteredCategories.isEmpty ? filteredCategories[indexPath.row] : categories[indexPath.row]
        delegate?.selected(category)
        dismiss(animated: true, completion: nil)
    }
}
