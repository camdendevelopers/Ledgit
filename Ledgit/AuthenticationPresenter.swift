//
//  AuthenticationPresenter.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 10/19/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import Foundation

enum Platform {
    case firebase
    case coreData
}

protocol AuthenticationPresenterDelegate: AnyObject {
    func successfulAuthentication(of user: LedgitUser)
    func displayError(_ error: LedgitError)
}

class AuthenticationPresenter {
    weak var delegate: AuthenticationPresenterDelegate?
    var manager: AuthenticationManager!

    init(manager: AuthenticationManager ) {
        self.manager = manager
        self.manager.delegate = self
    }

    func authenticateUser(platform: Platform, method: AuthenticationMethod, email: String = "", password: String = "") {
        switch method {
        case .signin:
            break

        case .signup:
            manager.performCoreDataSignUp()
        }
    }
}

extension AuthenticationPresenter: AuthenticationManagerDelegate {
    func userAuthenticated(_ user: LedgitUser) {
        delegate?.successfulAuthentication(of: user)
    }

    func authenticationError(_ error: LedgitError) {
        delegate?.displayError(error)
    }
}
