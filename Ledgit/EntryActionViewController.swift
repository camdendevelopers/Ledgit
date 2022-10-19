//
//  EntryActionViewController.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 10/15/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import NotificationBannerSwift

// swiftlint:disable file_length type_body_length
class EntryActionNavigationController: UINavigationController { }

class EntryActionViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var contentStackView: UIStackView!
    @IBOutlet var currencyAndAmountStackView: UIStackView!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var amountInHomeCurrencyLabel: UILabel!
    @IBOutlet var dateTextField: SkyFloatingLabelTextField!
    @IBOutlet var descriptionTextField: SkyFloatingLabelTextField!
    @IBOutlet var locationTextField: SkyFloatingLabelTextField!
    @IBOutlet var amountTextField: SkyFloatingLabelTextField!
    @IBOutlet var currencyTextField: SkyFloatingLabelTextField!
    @IBOutlet var categoryTextField: SkyFloatingLabelTextField!
    @IBOutlet var exchangeRateTextField: SkyFloatingLabelTextField!
    @IBOutlet var destinationTripTextField: SkyFloatingLabelTextField!
    @IBOutlet var textFields: [SkyFloatingLabelTextField]!
    @IBOutlet var paymentPickerCashButton: UIButton!
    @IBOutlet var paymentPickerCreditButton: UIButton!
    var isQuickAdd: Bool = false
    var action: LedgitAction = .add
    var editedEntry: Bool = false
    var keyboardShowing: Bool = false
    var isConnected: Bool { return Reachability.isConnectedToNetwork }
    var activeTextField: UITextField?
    var exchangeRateAttempts: Int = 0
    var selectedCurrency: LedgitCurrency = LedgitUser.current.homeCurrency {
        didSet {
            amountTextField.title = "AMOUNT IN \(selectedCurrency.code.uppercased())"
            amountTextField.selectedTitle = "AMOUNT IN \(selectedCurrency.code.uppercased())"

            guard selectedCurrency != LedgitUser.current.homeCurrency else {
                exchangeRateTextField.text("1.00")
                updateHomeCurrencyAmountLabelIfNeeded()
                return
            }

            fetchRateFor(currency: selectedCurrency)
        }
    }

    var selectedCategory: String?
    var datePicker: UIDatePicker?
    var presenter: TripDetailPresenter?
    var entry: LedgitEntry?
    var parentTrip: LedgitTrip?
    var paymentType: PaymentType = .cash {
        didSet {
            switch paymentType {
            case .cash:
                paymentPickerCreditButton.backgroundColor = .clear
                paymentPickerCashButton.backgroundColor = .white
            case .credit:
                paymentPickerCreditButton.backgroundColor = .white
                paymentPickerCashButton.backgroundColor = .clear
            }
        }
    }

    var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = LedgitDateStyle.long.rawValue
        return formatter
    }

    // MARK: - Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupButtons()
        setupTextFields()
        setupObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.endEditing(true)
        activeTextField?.resignFirstResponder()
//        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        navigationController?.navigationBar.shadowImage = UIImage()
//        navigationController?.view.backgroundColor = LedgitColor.coreBlue
//        navigationController?.navigationBar.barTintColor = LedgitColor.coreBlue
//        view.backgroundColor = LedgitColor.coreBlue
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        activeTextField?.resignFirstResponder()
        NotificationBannerQueue.default.removeAll()
    }

    func setupView() {
        contentStackView.setCustomSpacing(5, after: amountInHomeCurrencyLabel)
    }

    func setupButtons() {
        paymentPickerCashButton.roundedCorners(radius: paymentPickerCashButton.frame.height / 2, borderColor: .white)
        paymentPickerCreditButton.roundedCorners(radius: paymentPickerCreditButton.frame.height / 2, borderColor: .white)
        paymentType = .cash
    }

    func setupTextFields() {
        if action == .edit {
            guard let entry = entry else {
                showAlert(with: LedgitError.errorGettingEntry)
                dismiss(animated: true, completion: nil)
                return
            }

            title = "Edit Entry"
            selectedCurrency = entry.currency
            selectedCategory = entry.category
            categoryTextField.text(selectedCategory)
            currencyTextField.text(selectedCurrency.name)
            dateTextField.text(entry.date.toString(style: .long))
            locationTextField.text(entry.location)
            descriptionTextField.text(entry.description)
            amountTextField.text("\(entry.cost)".currencyFormat(with: entry.currency.symbol))
            amountTextField.title = "AMOUNT IN \(selectedCurrency.code.uppercased())"
            exchangeRateTextField.text("\(entry.exchangeRate)")

            paymentType = entry.paymentType

            deleteButton.isUserInteractionEnabled = true
            deleteButton.isHidden = false

        } else {
            dateTextField.text(Date().toString(style: .long))
            currencyTextField.text(selectedCurrency.name)
            if selectedCurrency == LedgitUser.current.homeCurrency { exchangeRateTextField.text("1.00") }
            destinationTripTextField.text = parentTrip?.name
        }

        dateTextField.delegate = self
        locationTextField.delegate = self
        descriptionTextField.delegate = self
        currencyTextField.delegate = self
        amountTextField.delegate = self
        categoryTextField.delegate = self
        exchangeRateTextField.delegate = self
        destinationTripTextField.delegate = self
        destinationTripTextField.isHidden = !isQuickAdd

        dateTextField.setTitleVisible(true)
        locationTextField.setTitleVisible(true)
        descriptionTextField.setTitleVisible(true)
        currencyTextField.setTitleVisible(true)
        amountTextField.setTitleVisible(true)
        categoryTextField.setTitleVisible(true)
        exchangeRateTextField.setTitleVisible(true)

        exchangeRateTextField.inputAccessoryView = createToolbar()
        amountTextField.inputAccessoryView = createToolbar()
        dateTextField.inputAccessoryView = createToolbar()
    }

    func setupObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    func createToolbar() -> UIToolbar {
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = LedgitColor.coreBlue
        toolBar.sizeToFit()

        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneTapped))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true

        return toolBar
    }

    @objc func doneTapped() {
        amountTextField.resignFirstResponder()
        exchangeRateTextField.resignFirstResponder()
        dateTextField.resignFirstResponder()
    }

    @objc func datePickerValueChanged(sender: UIDatePicker) {
        activeTextField?.text(formatter.string(from: sender.date))
    }

    @objc func multipleSelectorDone() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func paymentPickerCashButtonPressed(_ sender: Any) {
        paymentType = .cash
    }

    @IBAction func paymentPickerCreditButtonPressed(_ sender: Any) {
        paymentType = .credit
    }

    func amountTextFieldChanged(_ sender: SkyFloatingLabelTextField) {
        guard let text = sender.text else { return }
        sender.text(text.currencyFormat(with: selectedCurrency.symbol))
    }

    func updateHomeCurrencyAmountLabelIfNeeded() {
        guard LedgitUser.current.homeCurrency != selectedCurrency else {
            UIView.animate(withDuration: 0.25) {
                self.contentStackView.setCustomSpacing(self.contentStackView.spacing, after: self.currencyAndAmountStackView)
                self.amountInHomeCurrencyLabel.isHidden = true
            }
            return
        }

        guard let amountString = amountTextField.text?.strip(), !amountString.isEmpty else {
            UIView.animate(withDuration: 0.25) {
                self.amountInHomeCurrencyLabel.isHidden = true
                self.contentStackView.setCustomSpacing(self.contentStackView.spacing, after: self.currencyAndAmountStackView)
            }
            return
        }

        guard let exchangeRateString = exchangeRateTextField.text?.strip(), let exchangeRate = Double(exchangeRateString) else {
            UIView.animate(withDuration: 0.25) {
                self.amountInHomeCurrencyLabel.isHidden = true
                self.contentStackView.setCustomSpacing(self.contentStackView.spacing, after: self.currencyAndAmountStackView)
            }
            return
        }

        let amount = amountString.toDouble()
        let convertedCost = Double(amount / exchangeRate).currencyFormat()

        amountInHomeCurrencyLabel.text = "Amount in \(LedgitUser.current.homeCurrency.code): " + convertedCost

        UIView.animate(withDuration: 0.25) {
            self.contentStackView.setCustomSpacing(0, after: self.currencyAndAmountStackView)
            self.amountInHomeCurrencyLabel.isHidden = false
        }
    }

    @IBAction func deleteButtonPressed(_ sender: Any) {
        guard parentTrip?.key != Constants.ProjectID.sample else {
            showAlert(with: LedgitError.cannotAddEntriesToSample)
            return
        }

        guard let entry = entry else { return }
        let alert = UIAlertController(title: "Warning", message: "Are you sure you want to remove this entry? This can't be undone.", preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Nevermind", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.presenter?.remove(entry)
            self.dismiss(animated: true, completion: nil)
        }

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    @IBAction func closeButtonPressed(_ sender: Any) {

        if action == .edit && editedEntry && parentTrip?.key != Constants.ProjectID.sample {

            let alert = UIAlertController(title: "Just making sure...", message: "It looks like you made some changes, do you want to save them?", preferredStyle: .alert)

            let noThanksAction = UIAlertAction(title: "No thanks", style: .destructive, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            })

            let saveAction = UIAlertAction(title: "Yes please!", style: .cancel, handler: { _ in
                self.saveButtonPressed(self)
            })

            alert.addAction(saveAction)
            alert.addAction(noThanksAction)

            present(alert, animated: true, completion: nil)

        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    func textFieldsValidated() -> Bool {
        var validated = true
        if amountTextField.text?.isEmpty == true {
            amountTextField.errorMessage = "Enter an amount"
            validated = false
        }

        if exchangeRateTextField.text?.isEmpty == true {
            exchangeRateTextField.errorMessage = "Enter a rate"
            validated = false
        }

        return validated
    }

    func displayNoNetworkOrSavedRateBanner() {
        let subtitleText = "You're not connected to the internet and there is no saved rate for this currency yet. Connect to the internet and tap to try again, or enter you're own custom rate."
        let banner = GrowingNotificationBanner(title: "Heads Up!",
                                               subtitle: subtitleText,
                                               style: .danger)
        banner.autoDismiss = false
        banner.dismissOnTap = true
        banner.onTap = {
            guard self.exchangeRateAttempts < 1 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.fetchRateFor(currency: self.selectedCurrency)
                self.exchangeRateAttempts += 1
            })
        }
        banner.show(queuePosition: .front, bannerPosition: .bottom, queue: .default, on: self)
    }

    func displayExchangeServiceBannner() {
        let subtitleText = "The exchange rate service seems to be down at the moment. Please enter an exchange rate and try again later "
        let banner = GrowingNotificationBanner(title: "Heads Up!",
                                               subtitle: subtitleText,
                                               style: .danger)
        banner.autoDismiss = true
        banner.dismissOnTap = true
        banner.onTap = {
            guard self.exchangeRateAttempts < 1 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.fetchRateFor(currency: self.selectedCurrency)
                self.exchangeRateAttempts += 1
            })
        }
        banner.show(queuePosition: .front, bannerPosition: .bottom, queue: .default, on: self)
    }

    func fetchRateFor(currency: LedgitCurrency) {
        LedgitCurrency.getRate(between: LedgitUser.current.homeCurrency.code, and: currency.code) { result in
            switch result {
            case .success(let rate):
                self.exchangeRateTextField.text("\(rate)")

            case .failure(let error):

                switch error {
                case LedgitCurrencyFetchError.noNetworkOrSavedRate:
                    self.displayNoNetworkOrSavedRateBanner()
                    self.exchangeRateTextField.text = nil

                case LedgitCurrencyFetchError.currencyService:
                    self.displayExchangeServiceBannner()
                    self.exchangeRateTextField.text = nil
                default:
                    break
                }

                LedgitLog.critical("In \(self), we were unable to fetch rate between \(LedgitUser.current.homeCurrency.code) selecting \(self.selectedCurrency.code)")
                LedgitLog.error(error)
            }

            self.updateHomeCurrencyAmountLabelIfNeeded()
        }
    }

    @IBAction func saveButtonPressed(_ sender: Any) { // swiftlint:disable:this function_body_length
        guard parentTrip?.key != Constants.ProjectID.sample else {
            showAlert(with: LedgitError.cannotAddEntriesToSample)
            return
        }

        guard
            textFieldsValidated(),
            let amountString = amountTextField.text?.strip(),
            let exchangeRateString = exchangeRateTextField.text?.strip(),
            let exchangeRate = Double(exchangeRateString),
            let date = dateTextField.text?.strip(),
            let owningTripKey = presenter?.trip.key
        else { return }

        let pendingLocation = locationTextField.text?.strip() ?? ""
        let location = pendingLocation.isEmpty ? "Unknown" : pendingLocation

        let pendingDescription = descriptionTextField.text?.strip() ?? ""
        let description = pendingDescription.isEmpty ? "No description" : pendingDescription
        let category = selectedCategory ?? "Miscellaneous"

        let amount = amountString.toDouble()
        let convertedCost = Double(amount / exchangeRate)

        var key = ""
        if action == .edit, let entry = entry {
            key = entry.key
        } else {
            key = UUID().uuidString
        }

        let queryString = LedgitUser.current.homeCurrency.code + "_" + selectedCurrency.code
        let queryStringDate = queryString + "_date"
        UserDefaults.standard.set(Date(), forKey: queryStringDate)
        UserDefaults.standard.set(exchangeRate, forKey: queryString)

        let entryData: NSDictionary = [
            LedgitEntry.Keys.key: key,
            LedgitEntry.Keys.date: date,
            LedgitEntry.Keys.location: location,
            LedgitEntry.Keys.description: description,
            LedgitEntry.Keys.category: category,
            LedgitEntry.Keys.currency: selectedCurrency.code,
            LedgitEntry.Keys.homeCurrency: LedgitUser.current.homeCurrency.code,
            LedgitEntry.Keys.exchangeRate: exchangeRate,
            LedgitEntry.Keys.paymentType: paymentType.rawValue,
            LedgitEntry.Keys.cost: amount,
            LedgitEntry.Keys.convertedCost: convertedCost,
            LedgitEntry.Keys.paidBy: LedgitUser.current.key,
            LedgitEntry.Keys.owningTrip: owningTripKey
        ]

        if action == .edit {
            presenter?.update(entry: entryData)
        } else {
            presenter?.create(entry: entryData)
        }

        dismiss(animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.SegueIdentifiers.tripSelection {
            let navigationController = segue.destination as? UINavigationController
            let tripSelectionController = navigationController?.topViewController as? TripSelectionTableViewController
            tripSelectionController?.delegate = self
        }
    }
}

extension EntryActionViewController: CategorySelectionDelegate {
    func selected(_ category: String) {
        selectedCategory = category
        categoryTextField.text(category)
    }
}

extension EntryActionViewController: CurrencySelectionDelegate {
    func selected(_ currencies: [LedgitCurrency]) {
        guard let currency = currencies.first else { return }
        selectedCurrency = currency
        currencyTextField.text(currency.name)
        amountTextFieldChanged(amountTextField)
    }
}

extension EntryActionViewController: UITextFieldDelegate {
    func adjustInsetForKeyboardShow(_ show: Bool, notification: Notification) {
        guard let info = notification.userInfo else { return }
        guard let keyboard = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom += keyboard.height
        scrollView.verticalScrollIndicatorInsets.bottom += keyboard.height
    }

    @objc func keyboardWillShow(notification: Notification) {
        guard !keyboardShowing else { return }
        guard let info = notification.userInfo else { return }
        guard let keyboard = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        scrollView.contentInset.bottom += keyboard.height
        scrollView.verticalScrollIndicatorInsets.bottom += keyboard.height
        keyboardShowing = true
    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
        keyboardShowing = false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        editedEntry = true
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch textField {
        case currencyTextField:
            currencyTextField.errorMessage = nil
            let currencySelectionViewController = CurrencySelectionViewController.instantiate(from: .trips)
            currencySelectionViewController.delegate = self
            currencySelectionViewController.allowsMultipleSelection = false
            currencySelectionViewController.limitedCurrencies = parentTrip?.currencies
            currencySelectionViewController.title = "Select Currency"

            let navigationController = UINavigationController(rootViewController: currencySelectionViewController)
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: currencySelectionViewController, action: #selector(CurrencySelectionViewController.dismissViewController))
            doneButton.tintColor = LedgitColor.coreBlue
            navigationController.navigationBar.isTranslucent = false
            navigationController.topViewController?.navigationItem.setRightBarButton(doneButton, animated: true)

            activeTextField?.resignFirstResponder()
            present(navigationController, animated: true, completion: nil)

            return false

        case categoryTextField:
            categoryTextField.errorMessage = nil

            let categorySelectionViewController = CategorySelectionViewController.instantiate(from: .trips)
            categorySelectionViewController.delegate = self
            categorySelectionViewController.title = "Select Category"

            let navigationController = UINavigationController(rootViewController: categorySelectionViewController)
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: categorySelectionViewController, action: #selector(CategorySelectionViewController.dismissViewController))
            doneButton.tintColor = LedgitColor.coreBlue
            navigationController.navigationBar.isTranslucent = false
            navigationController.topViewController?.navigationItem.setRightBarButton(doneButton, animated: true)

            activeTextField?.resignFirstResponder()
            present(navigationController, animated: true, completion: nil)
            return false

        case destinationTripTextField:
            performSegue(withIdentifier: Constants.SegueIdentifiers.tripSelection, sender: nil)
            return false

        case dateTextField:
            datePicker = UIDatePicker()
            datePicker?.datePickerMode = .date
            datePicker?.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)

            dateTextField.inputView = datePicker
            dateTextField.errorMessage = nil
            if let dateString = dateTextField.text {
                let date = dateString.toDate()
                datePicker?.setDate(date, animated: false)
            }
            return true

        default:
            return true
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField

        switch textField {
        case locationTextField:
            locationTextField.errorMessage = nil

        case descriptionTextField:
            descriptionTextField.errorMessage = nil

        case amountTextField:
            guard let text = textField.text else { return }
            let cleanedText = text.trimmingCharacters(in: CharacterSet(charactersIn: ".1234567890").inverted)
            textField.text(cleanedText.replacingOccurrences(of: ",", with: ""))

        default: break
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == amountTextField {
            updateHomeCurrencyAmountLabelIfNeeded()
            guard let text = textField.text else {
                amountTextField.errorMessage = "Enter an amount in \(selectedCurrency.code)"
                return
            }
            let cleanedText = text.trimmingCharacters(in: CharacterSet(charactersIn: ".1234567890").inverted)
            textField.text(cleanedText.currencyFormat(with: selectedCurrency.symbol))
            amountTextField.errorMessage = nil
        } else if textField == exchangeRateTextField {
            updateHomeCurrencyAmountLabelIfNeeded()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension EntryActionViewController: TripSelectionDelegate {
    func selected(_ trip: LedgitTrip) {
        parentTrip = trip
        presenter?.attach(trip)
        destinationTripTextField.text = trip.name
    }
}
