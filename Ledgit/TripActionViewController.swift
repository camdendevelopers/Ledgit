//
//  TripActionViewController.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 11/5/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit
import Firebase
import SkyFloatingLabelTextField
import NotificationBannerSwift

protocol TripActionDelegate {
    func added(trip dict: NSDictionary)
    func edited(_ trip: LedgitTrip)
}

class TripActionViewController: UIViewController {
    @IBOutlet weak var mapIconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var nameTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var startDateTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var endDateTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var budgetTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var currenciesTextField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var budgetPickerLabel: UILabel!
    @IBOutlet weak var budgetPickerDailyButton: UIButton!
    @IBOutlet weak var budgetPickerTripButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    let infoView = TripBudgetInformationView()
    let budgetPickerButtonHeight: CGFloat = 20
    var presenter: TripsPresenter?
    var delegate: TripActionDelegate?
    var trip: LedgitTrip?
    var banner: NotificationBanner?
    var method: LedgitAction = .add
    var selectedCurrencies: [Currency] = [.USD]
    var activeTextField = UITextField()
    var datePicker: UIDatePicker?
    var tripLength: Int = 1
    
    var isLoading:Bool = false {
        didSet {
            switch isLoading {
            case true: startLoading()
            case false: stopLoading()
            }
        }
    }
    
    var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = LedgitDateStyle.full.rawValue
        return formatter
    }
    
    var budgetSelection: BudgetSelection = .daily {
        didSet {
            switch budgetSelection {
            case .daily:
                budgetPickerLabel.text("DAILY")
                budgetPickerDailyButton.color(LedgitColor.navigationTextGray)
                budgetPickerTripButton.color(.clear)
            
            case .trip:
                budgetPickerLabel.text("TRIP")
                budgetPickerTripButton.color(LedgitColor.navigationTextGray)
                budgetPickerDailyButton.color(.clear)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBudgetPicker()
        setupTextFields()
        setupObservers()
        setupBars()
        setupView()
    }
    
    func setupView() {
        switch method {
        case .add:
            title = "Create Trip"
            titleLabel.text("Enter some details of your trip")
            actionButton.text("Create Trip")
            
        case .edit:
            title = "Edit Trip"
            titleLabel.text("Change the details of your trip")
            actionButton.text("Save")
        }
        
        actionButton.roundedCorners(radius: Constants.cornerRadius.button)
    }
    
    func setupTextFields() {
        if method == .edit {
            guard let trip = trip else {
                navigationController?.popViewController(animated: true)
                showAlert(with: Constants.clientErrorMessages.errorGettingTrip)
                return
            }
            
            nameTextField.text(trip.name)
            startDateTextField.text(trip.startDate)
            endDateTextField.text(trip.endDate)
            budgetTextField.text(String(trip.budget).currencyFormat())
            currenciesTextField.text(trip.currencies.map{ $0.code }.joined(separator: ","))
            selectedCurrencies = trip.currencies
            budgetSelection = trip.budgetSelection
            tripLength = trip.length
        }
        
        nameTextField.delegate = self
        startDateTextField.delegate = self
        endDateTextField.delegate = self
        budgetTextField.delegate = self
        currenciesTextField.delegate = self
        
        startDateTextField.inputAccessoryView = createToolbar()
        endDateTextField.inputAccessoryView = createToolbar()
        budgetTextField.inputAccessoryView = createToolbar()
    }
    
    func setupBudgetPicker() {
        budgetPickerDailyButton.roundedCorners(radius: budgetPickerButtonHeight / 2, borderColor: LedgitColor.navigationTextGray)
        budgetPickerTripButton.roundedCorners(radius: budgetPickerButtonHeight / 2, borderColor: LedgitColor.navigationTextGray)
        
        if method == .edit {
            guard let trip = trip else {
                navigationController?.popViewController(animated: true)
                showAlert(with: Constants.clientErrorMessages.errorGettingTrip)
                return
            }
            
            budgetSelection = trip.budgetSelection
        } else {
            budgetSelection = .daily
        }
    }
    
    func setupObservers() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    func setupBars(){
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.isOpaque = true
    }
    
    func createToolbar() -> UIToolbar {
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 92/255, green: 216/255, blue: 255/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneTapped))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        return toolBar
    }
    
    func textFieldsValidated() -> Bool {
        var validated = true
        
        if nameTextField.text?.isEmpty == true {
            nameTextField.errorMessage = "Enter a city"
            validated = false
        }
        
        if startDateTextField.text?.isEmpty == true {
            startDateTextField.errorMessage = "Enter a description"
            validated = false
        }
        
        if endDateTextField == nil {
            endDateTextField.errorMessage = "Select a category"
            validated = false
        }
        
        if budgetTextField.text?.isEmpty == true {
            budgetTextField.errorMessage = "Enter an amount"
            validated = false
        }

        return validated
    }
    
    func performSaveAction() {
        guard
            textFieldsValidated(),
            let name = nameTextField.text,
            let startDate = startDateTextField.text,
            let endDate = endDateTextField.text,
            let budget = budgetTextField.text
        else {
            showAlert(with: Constants.clientErrorMessages.emptyTextFields)
            return
        }
        
        let key = UUID().uuidString
        
         let dict: NSDictionary = [
         LedgitTrip.Keys.name: name,
         LedgitTrip.Keys.startDate: startDate,
         LedgitTrip.Keys.endDate: endDate,
         LedgitTrip.Keys.currencies: selectedCurrencies.map{ $0.code },
         LedgitTrip.Keys.length: tripLength,
         LedgitTrip.Keys.budget: budget.toDouble(),
         LedgitTrip.Keys.budgetSelection: budgetSelection.rawValue,
         LedgitTrip.Keys.users: "",
         LedgitTrip.Keys.key: key,
         LedgitTrip.Keys.owner: LedgitUser.current.key
         ]
        
        delegate?.added(trip: dict)
        navigationController?.popViewController(animated: true)
    }
    
    func performUpdateAction() {
        guard
            textFieldsValidated(),
            let name = nameTextField.text,
            let startDate = startDateTextField.text,
            let endDate = endDateTextField.text,
            let budget = budgetTextField.text
        else {
            showAlert(with: Constants.clientErrorMessages.emptyTextFields)
            return
        }
        
        if var trip = trip {
            trip.name = name
            trip.startDate = startDate
            trip.endDate = endDate
            trip.budget = budget.toDouble()
            trip.currencies = selectedCurrencies
            trip.budgetSelection = budgetSelection
            trip.length = tripLength
            
            delegate?.edited(trip)
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func budgetPickerDailyButtonPressed(_ sender: Any) {
        budgetSelection = .daily
        showBudgetInformationBanner()
    }
    
    @IBAction func budgetPickerTripButtonPressed(_ sender: Any) {
        budgetSelection = .trip
        showBudgetInformationBanner()
    }
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        switch method {
        case .edit:
            performUpdateAction()
            
        case .add:
            performSaveAction()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        activeTextField.resignFirstResponder()
        if segue.identifier == Constants.segueIdentifiers.currencySelection {
            guard let destinationViewController = segue.destination as? CurrencySelectionViewController else { return }
            destinationViewController.delegate = self
            destinationViewController.selectedCurrencies = selectedCurrencies
        }
    }
}

extension TripActionViewController: UITextFieldDelegate {
    @objc func keyboardWillShow(notification:NSNotification){
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        guard let info = notification.userInfo else { return }
        guard let keyboard = info[UIKeyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboard.height, right: 0)
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = .zero
        scrollView.contentInset = contentInset
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        
        if textField == startDateTextField || textField == endDateTextField {
            datePicker = UIDatePicker()
            datePicker?.datePickerMode = .date
            datePicker?.backgroundColor = .white
            datePicker?.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
            textField.inputView = datePicker
            
            // If there is previous text before
            if let text = textField.text, !text.isEmpty {
                let date = text.toDate()
                datePicker?.setDate(date, animated: true)
                datePickerValueChanged(sender: datePicker!)
                return
            }
            
            switch method {
            case .edit:
                guard let trip = trip else { return }
                let dateString = (textField == startDateTextField) ? trip.startDate : trip.endDate
                let date = dateString.toDate()
                datePicker?.setDate(date, animated: true)
                datePickerValueChanged(sender: datePicker!)
                
            case .add:
                if textField == endDateTextField, let startDateText = startDateTextField.text, !startDateText.isEmpty {
                    let date = startDateText.toDate().add(components: 1.day)
                    datePicker?.setDate(date, animated: true)
                    datePickerValueChanged(sender: datePicker!)
                    
                } else {
                    let now = Date()
                    datePicker?.setDate(now, animated: true)
                    datePickerValueChanged(sender: datePicker!)
                }
            }
            
        } else if textField == currenciesTextField {
            performSegue(withIdentifier: Constants.segueIdentifiers.currencySelection, sender: self)
            
        } else if textField == budgetTextField {
            guard let text = textField.text else { return }
            let budgetText = text.replacingOccurrences(of: LedgitUser.current.homeCurrency.symbol, with: "").replacingOccurrences(of: ",", with: "")
            textField.text(budgetText)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == budgetTextField {
            guard let text = textField.text else { return }
            textField.text(text.currencyFormat())
            showBudgetInformationBanner()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField, budgetTextField, currenciesTextField:
            textField.resignFirstResponder()
            
        default: break
        }
        return true
    }
    
    @objc func doneTapped() {
        activeTextField.resignFirstResponder()
    }
    
    @objc func datePickerValueChanged(sender: UIDatePicker) {
        activeTextField.text(formatter.string(from: sender.date))
        
        guard
            let startDateText = startDateTextField.text?.strip(),
            let endDateText = endDateTextField.text?.strip(),
            let startDate = formatter.date(from: startDateText),
            let endDate = formatter.date(from: endDateText)
        else {
            Log.info("Either startDate or endDate not yet available")
            return
        }
        
        if validate(startDate, isBefore: endDate) {
            // If startDate is BEFORE endDate,
            // set the trip length
            setTripLength(from: startDate, to: endDate)
            
        } else {
            // If startDate is NOT before endDate,
            // set the endDateTextField to the start date
            endDateTextField.text(formatter.string(from: startDate))
        }
    }
    
    func validate(_ startDate: Date, isBefore endDate: Date) -> Bool {
        guard startDate.isBefore(date: endDate, granularity: .day) else { return false }
        return true
    }
    
    func setTripLength(from startDate: Date, to endDate: Date) {
        let calendar = Calendar.current
        guard let daysBetweenDates = calendar.dateComponents([.day], from: startDate, to: endDate).day else { return }
        tripLength = daysBetweenDates
        Log.info("Days between \(startDate) and \(endDate) is \(tripLength)")
    }
    
    func showBudgetInformationBanner() {
        guard
            let budgetText = budgetTextField.text?.strip(),
            let startText = startDateTextField.text,
            let endText = endDateTextField.text,
            !startText.isEmpty,
            !endText.isEmpty,
            !budgetText.isEmpty
        else { return }
        
        infoView.configure(with: budgetText, selection: budgetSelection, tripLength: tripLength)
        banner = NotificationBanner(customView: infoView)
        banner?.dismissOnTap = true
        banner?.bannerHeight = 110
        banner?.duration = 3.0
        banner?.show(queuePosition: .front, bannerPosition: .top, queue: .default, on: nil)
    }
}

extension TripActionViewController: CurrencySelectionDelegate {
    func selected(_ currencies: [Currency]) {
        selectedCurrencies = currencies
        currenciesTextField.text(currencies.map{ $0.code }.joined(separator: ", "))
        currenciesTextField.resignFirstResponder()
    }
}
