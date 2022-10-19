//
//  LedgitError.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 4/14/18.
//  Copyright © 2018 Camden Developers. All rights reserved.
//

import Foundation

struct LedgitError {
    let title: String
    let message: String
}

extension LedgitError { // Client Side Errors

    static let freeSubscriptions = LedgitError(title: "Hooray For You!",
                                               message: "We're still testing this, so for now it's all free 😉")

    static let emptyUserPasswordTextFields = LedgitError(title: "Could Not Sign In",
                                                         message: "Email/password fields are empty.")

    static let emptyTextFields = LedgitError(title: "Oops",
                                             message: "Make sure sure to fill out all text fields to continue")

    static let invalidUserPasswordTextFields = LedgitError(title: "Could Not Create Account",
                                                           message: "The email or password is invalid. Please try again.")

    static let iPhoneTryUpload = LedgitError(title: "Can't Add Custom Image",
                                             message: "Sorry, changing image is not available on this phone.")

    static let noNetworkConnection = LedgitError(title: "Error",
                                                 message: "Your phone isn't connected to the internet, make sure you have a working connection and try again later.")

    static let confirmDeleteTrip = LedgitError(title: "Warning",
                                               message: "Are you sure you want to delete this trip?")

    static let noCameraAvailable = LedgitError(title: "Warning",
                                               message: "You don't have a camera.")

    static let authenticationError = LedgitError(title: "Error",
                                                 message: "Something went wrong with Facebook authentication. Please try again.")

    static let resetInstructionsSent = LedgitError(title: "Hooray",
                                                   message: "We sent you an email to reset your password.")

    static let cannotAddEntriesToSample = LedgitError(title: "Not So Fast",
                                                      message: "You can't change entries on this sample trip. Go back and create one if you haven't done so already.")

    static let errorGettingTrip = LedgitError(title: "Please Excuse Us",
                                              message: "We had some trouble getting your trip details. Try again later.")

    static let errorGettingEntry = LedgitError(title: "Please Excuse Us",
                                               message: "We had some trouble getting your entry details. Try again later.")
}

extension LedgitError { // Authentication errors
    static let coreDataFault = LedgitError(title: "Error",
                                           message: "Could not create your initial account. Sorry about that!")

    static let cancelled = LedgitError(title: "Hmmm...",
                                       message: "It looks like you cancelled, try again or select another method.")

    static let general = LedgitError(title: "Could Not Sign In",
                                     message: "Error getting your information. Please try again later.")

    static let userDisabled = LedgitError(title: "Could Not Sign In",
                                          message: "Error getting your information. Please try again later.")

    static let operationNotAllowed = LedgitError(title: "Could Not Sign In",
                                                 message: "Error getting your information. Please try again later.")

    static let emailAlreadyInUse = LedgitError(title: "Hold on a sec...",
                                               message: "Email is already being used. Please try using a different one.")

    static let invalidEmail = LedgitError(title: "Could Not Sign In",
                                          message: "Invalid email, try again.")

    static let wrongPassword = LedgitError(title: "Could Not Sign In",
                                           message: "Invalid password, try again.")

    static let userNotFound = LedgitError(title: "Could Not Sign In",
                                          message: "User with these credentials not found. Sign up and make a new account.")

    static let weakPassword = LedgitError(title: "Could Not Create Account",
                                          message: "That is a weak password. Try using uppercase/lowercase/special characters.")

    static let invalidCredential = LedgitError(title: "Could Not Sign In With Facebook",
                                               message: "Error getting your information. Please try again later.")
}

extension LedgitError: Equatable {
    static func == (lhs: LedgitError, rhs: LedgitError) -> Bool {
        return lhs.title == rhs.title && lhs.message == rhs.message
    }
}
