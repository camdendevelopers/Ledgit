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
        setupPresenter()
        setupTableView()
        setupAddButton()
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
        let rightButton:UIButton = UIButton()
        rightButton.setImage(#imageLiteral(resourceName: "add-icon"), for: .normal)
        rightButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        
        let barButton = UIBarButtonItem(customView: rightButton)
        navigationItem.rightBarButtonItem = barButton
    }
    
    @objc func addButtonPressed() {
        performSegue(withIdentifier: Constants.segueIdentifiers.categoryAction, sender: CategoryAction.add)
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

extension CategoriesViewController: UITableViewDelegate, UITableViewDataSource{

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        selectedIndexPath = indexPath
        
        let edit = UITableViewRowAction(style: .destructive, title: "Edit") { (action, path) in
           self.performSegue(withIdentifier: Constants.segueIdentifiers.categoryAction, sender: CategoryAction.edit)
        }
        edit.backgroundColor = LedgitColor.coreYellow
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, path) in
            self.presenter?.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
        return [delete, edit]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter?.categories.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifiers.categoryName, for: indexPath) as! CategoryTableViewCell
        cell.titleLabel.text(presenter?.categories[indexPath.row])
        
        if indexPath.row == tableView.lastRow() && !displayedInformationLabel {
            cell.displayInformationLabel(on: categoriesTableView)
            displayedInformationLabel = true
        }
        return cell
    }
}
