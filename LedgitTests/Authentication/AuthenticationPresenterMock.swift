//
//  AuthenticationPresenterMock.swift
//  LedgitTests
//
//  Created by Marcos Ortiz on 2/10/18.
//  Copyright © 2018 Camden Developers. All rights reserved.
//

import Foundation
@testable import Ledgit

class AuthenticationPresenterMock: AuthenticationPresenter {
    var didCallAuthenticateUser: Bool = false
    
    override func authenticateUser(platform: Platform, method: AuthenticationMethod, email: String, password: String) {
        didCallAuthenticateUser = true
    }
}
