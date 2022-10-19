//
//  Utilities.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 8/12/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit
import AMPopTip

enum Storyboard: String {
    case main = "Main"
    case trips = "Trips"
    case settings = "Settings"

    var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: nil)
    }

    func viewController<Element: UIViewController>(of viewControllerClass: Element.Type) -> Element {
        let storyboardID = (viewControllerClass as UIViewController.Type).storyboardID
        return instance.instantiateViewController(withIdentifier: storyboardID) as! Element // swiftlint:disable:this force_cast
    }

    func initialViewController() -> UIViewController? {
        return instance.instantiateInitialViewController()
    }
}

enum AuthenticationMethod {
    case signin, signup
}

enum LedgitAction {
    case add, edit
}

struct DateSection {
    var date: Date
    var entries: [LedgitEntry]
    var collapsed: Bool = false
}

struct CitySection {
    var location: String
    var amount: Double
}

enum PaymentType: String {
    case credit = "Credit"
    case cash = "Cash"
}

enum Subscription: String {
    case free = "Free"
    case paid = "Paid"
}

enum BudgetSelection: String {
    case daily = "Daily"
    case trip = "Trip"
}

enum LedgitDateStyle: String {
    case full = "MMMM d, yyyy"
    case long = "MMM d, yyyy"
    case medium = "EEEE, MMM d"
    case month = "MMM"
    case short = "MM/dd/yyyy"
    case day = "E"
    case year = "yyyy"
}

infix operator <=: NilCoalescingPrecedence
public func <= <T>(lhs: inout T, rhs: T?) {
    lhs = rhs ?? lhs
}

func makeError(_ string: String) -> Error {
    return NSError(domain: "LedgitErrorDomain",
                   code: 1,
                   userInfo: [NSLocalizedDescriptionKey: string])
}

struct LedgitLog {
    static func debug(_ string: String,
                      _ method: String = #function,
                      _ line: Int = #line) {
        print("\(Date()): <DEBUG>\t\(string)")
    }

    static func info(_ string: String,
                     _ method: String = #function,
                     _ line: Int = #line) {
        print("\(Date()): <INFO>\t\(string)")
    }

    static func warning(_ string: String,
                        _ method: String = #function,
                        _ line: Int = #line) {
        print("\(Date()): <WARNING>\t\(string)")
    }

    static func critical(_ string: String,
                         _ method: String = #function,
                         _ line: Int = #line) {
        print("\(Date()): <CRITICAL>\t\(string)")
    }

    static func error(_ error: Error,
                      _ method: String = #function,
                      _ line: Int = #line) {
        print("\(Date()): <ERROR>\t\(error.localizedDescription)")
    }
}

struct Utilities {
    static func createCSV(with trip: LedgitTrip, and entries: [LedgitEntry]) -> URL? {

        // The name of the report
        let reportName = trip.name.strip() + "-Expenses.csv"

        // The path of the report
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(reportName)

        // Compute final trip amount
        let tripAmount = trip.budgetSelection == .daily ? trip.budget * Double(trip.length) : trip.budget

        // Lay out the trip information
        let tripText =  """
        Trip Name, \(trip.name)
        Start Date, \(trip.startDate.replacingOccurrences(of: ",", with: ""))
        End Date, \(trip.endDate.replacingOccurrences(of: ",", with: ""))
        Trip Length, \(trip.length)
        Total Amount, \(String(tripAmount))
        ,,
        """

        // Setup the headers
        var entryText = "\nLocation, Date, Description, Category, Payment Type, Cost, Exchange Rate, Converted Cost, Payment Currency, Home Currency\n"

        // Add entry information for each header
        entries.forEach { entry in
            entryText += "\(entry.location), \(entry.date.toString(style: .full).replacingOccurrences(of: ",", with: "")),"
            entryText += " \(entry.description), \(entry.category), \(entry.paymentType.rawValue), \(entry.cost),"
            entryText += " \(entry.exchangeRate), \(entry.convertedCost), \(entry.currency.code), \(entry.homeCurrency.code)\n"
        }

        // Create final string for csv file
        let finalText = tripText + entryText

        do {
            try finalText.write(to: path, atomically: true, encoding: .utf8)

        } catch let error {

            LedgitLog.critical("Could not gerated csv due to \(error.localizedDescription)")
        }

        return path
    }
}

struct PopStyle {
    static let `default` = { (tip: PopTip) in
        tip.bubbleColor = LedgitColor.coreBlue
        tip.shouldDismissOnTap = true
        tip.actionAnimation = .pulse(1.05)
        tip.entranceAnimation = .scale
        tip.exitAnimation = .scale
    }

    static let critical = { (tip: PopTip) in
        tip.bubbleColor = LedgitColor.coreRed
        tip.shouldDismissOnTap = true
        tip.actionAnimation = .pulse(1.05)
        tip.entranceAnimation = .scale
        tip.exitAnimation = .scale
    }

    static let warning = { (tip: PopTip) in
        tip.bubbleColor = LedgitColor.coreYellow
        tip.shouldDismissOnTap = true
        tip.actionAnimation = .pulse(1.05)
        tip.entranceAnimation = .scale
        tip.exitAnimation = .scale
    }

    static let confirm = { (tip: PopTip) in
        tip.bubbleColor = LedgitColor.coreYellow
        tip.shouldDismissOnTap = true
        tip.actionAnimation = .pulse(1.05)
        tip.entranceAnimation = .scale
        tip.exitAnimation = .scale
    }
}
