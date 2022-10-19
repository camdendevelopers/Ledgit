//
//  CategoriesViewController.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 8/23/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit

class CategoriesViewController: UIViewController {
    @IBOutlet weak var categoriesTableView: UITableView!
    weak var presenter: SettingsPresenter?
    var selectedIndexPath = IndexPath()
    var displayedInformationLabel: Bool = false
    var actionViewBackground:UIView?
    var actionViewTag = 1234

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupPresenter()
        setupTableView()
        setupAddButton()
    }

    func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
    }

    func setupPresenter() {
        presenter?.categoryDelegate = self
        presenter?.fetchCategories()
    }

    func setupTableView() {
        categoriesTableView.delegate = self
        categoriesTableView.dataSource = self
    }

    func setupAddButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
    }

    @objc func addButtonPressed() {
        performSegue(withIdentifier: Constants.SegueIdentifiers.categoryAction, sender: CategoryAction.add)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let categoryActionViewController = segue.destination as? CategoryActionViewController else { return }
        guard let action = sender as? CategoryAction else { return }

        categoryActionViewController.action = action
        categoryActionViewController.presenter = presenter
        categoryActionViewController.category = action == .edit ? presenter?.categories[selectedIndexPath.row] : nil
    }
}

extension CategoriesViewController: SettingsPresenterCategoryDelegate {
    func addedCategory() {
        categoriesTableView.beginUpdates()
        categoriesTableView.insertRows(at: [IndexPath(row: categoriesTableView.numberOfRows(inSection: 0), section: 0)], with: .left)
        categoriesTableView.endUpdates()
    }

    func updatedCategory() {
        categoriesTableView.reloadRows(at: [selectedIndexPath], with: .fade)
    }

    func retrievedCategories() {
        categoriesTableView.reloadData()
    }
}

extension CategoriesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        selectedIndexPath = indexPath

        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { _ in
                self.performSegue(withIdentifier: Constants.SegueIdentifiers.categoryAction, sender: CategoryAction.edit)
            }

            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.presenter?.remove(at: indexPath.row)
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            }

            return UIMenu(title: "Category Options", children: [edit, delete])
        }
        return configuration
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter?.categories.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifiers.categoryName, for: indexPath) as! CategoryTableViewCell // swiftlint:disable:this force_cast
        cell.titleLabel.text(presenter?.categories[indexPath.row])

        if indexPath.row == tableView.lastRow() && !displayedInformationLabel {
            cell.displayInformationLabel(on: categoriesTableView)
            displayedInformationLabel = true
        }
        return cell
    }
}
