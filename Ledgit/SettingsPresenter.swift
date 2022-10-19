//
//  SettingsPresenter.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 11/20/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import Foundation

enum SignoutResult {
    case success
    case failure(Error)
}

protocol SettingsPresenterDelegate: AnyObject {
    func signedout()
}

protocol SettingsPresenterCategoryDelegate: AnyObject {
    func retrievedCategories()
    func addedCategory()
    func updatedCategory()
}

class SettingsPresenter {
    let manager: SettingsManager!
    weak var delegate: SettingsPresenterDelegate?
    weak var categoryDelegate: SettingsPresenterCategoryDelegate?
    var categories:[String] = []

    init(manager: SettingsManager) {
        self.manager = manager
        self.manager.delegate = self
    }
}

extension SettingsPresenter {
    func signout() {
        manager.signout()
    }

    func fetchCategories() {
        manager.fetchCategories()
    }

    func update(_ category: String, to newCategory: String) {
        manager.updateCategory(to: newCategory, from: category)
    }

    func add(_ category: String) {
        manager.add(category: category)
    }

    func remove(at index: Int) {
        let category = categories[index]
        categories.remove(at: index)
        manager.remove(category)
    }

    func updateUser(name: String, email: String) {
        manager.updateUser(name: name, email: email)
    }

    func updateHomeCurrency(with currency: LedgitCurrency) {
        manager.updateUserHomeCurrency(with: currency)
    }
}

extension SettingsPresenter: SettingsManagerDelegate {
    func signedout(_ result: SignoutResult) {
        switch result {
        case .success:
            delegate?.signedout()
        case .failure(let error):
            LedgitLog.error(error)
        }
    }

    func retrieved(_ categories: [String]) {
        self.categories = categories
        categoryDelegate?.retrievedCategories()
    }

    func added(_ category: String) {
        categories.append(category)
        categoryDelegate?.addedCategory()
    }

    func updated(_ categories: [String]) {
        self.categories = categories
        categoryDelegate?.updatedCategory()
    }
}
