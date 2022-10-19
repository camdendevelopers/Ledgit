//
//  SummaryViewController.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 2/28/19.
//  Copyright © 2019 Camden Developers. All rights reserved.
//

import UIKit
import Charts
import SwiftDate
import AMPopTip

class SummaryViewController: UIViewController, ChartViewDelegate {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var amountsStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var weeklyChart: BarChartView!
    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var dayCostTitleLabel: UILabel!
    @IBOutlet var dayCostLabel: UILabel!
    @IBOutlet var remainingStackView: UIStackView!
    @IBOutlet var remainingTitleLabel: UILabel!
    @IBOutlet var remainingLabel: UILabel!

    @IBOutlet var budgetStackView: UIStackView!
    @IBOutlet var budgetTitleLabel: UILabel!
    @IBOutlet var budgetLabel: UILabel!
    @IBOutlet var averageStackView: UIStackView!
    @IBOutlet var averageTitleLabel: UILabel!
    @IBOutlet var averageLabel: UILabel!

    @IBOutlet var totalTripCostTitleLabel: UILabel!
    @IBOutlet var totalTripCostLabel: UILabel!
    @IBOutlet var estimatedTripCostTitleLabel: UILabel!
    @IBOutlet var estimatedTripCostLabel: UILabel!

    var averageCost: Double = 0
    var costToday: Double = 0
    var totalCost: Double = 0
    var estimatedTotalCost: Double = 0
    var dates: [Date] = []
    var values:[BarChartDataEntry] = []
    var amounts = [Double](repeating: 0, count: 7)
    var weekdays:[String] = [
        (Date() - 6.days).toString(style: .day),
        (Date() - 5.days).toString(style: .day),
        (Date() - 4.days).toString(style: .day),
        (Date() - 3.days).toString(style: .day),
        (Date() - 2.days).toString(style: .day),  // etc..
        (Date() - 1.days).toString(style: .day),  // Yesterday
        "Today"
    ]

    weak var presenter: TripDetailPresenter?
    var needsLayout: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLabelStyles()
        setupLabels()
        defaultChartSetup()
        setupStackViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        needsLayout ? setupLayout() : nil
        needsLayout = false
    }

    func setupView() {
        contentView.layer.cornerRadius = 10
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.clear.cgColor
        contentView.layer.masksToBounds = false

        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0 ,height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOpacity = 0.10

        amountsStackViewTopConstraint.constant = Type.iphone4 || Type.iphone5 ? 10 : 25
    }

    func setupLabelStyles() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        if #available(iOS 13.0, *) {
            weeklyChart.xAxis.labelTextColor = isDarkMode ? .white : LedgitColor.navigationTextGray
            weeklyChart.data?.setValueTextColor(isDarkMode ? .white : LedgitColor.coreBlue)
            dayLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            dayCostTitleLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            dayCostLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            remainingTitleLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            averageTitleLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            averageLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            budgetTitleLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            budgetLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            totalTripCostTitleLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            totalTripCostLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            estimatedTripCostTitleLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
            estimatedTripCostLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
        } else {
            weeklyChart.xAxis.labelTextColor = LedgitColor.navigationTextGray
            weeklyChart.data?.setValueTextColor(LedgitColor.coreBlue)
            dayLabel.color(LedgitColor.coreBlue)
            dayCostTitleLabel.color(LedgitColor.navigationTextGray)
            dayCostLabel.color(LedgitColor.navigationTextGray)
            remainingTitleLabel.color(LedgitColor.navigationTextGray)
            averageTitleLabel.color(LedgitColor.navigationTextGray)
            averageLabel.color(LedgitColor.navigationTextGray)
            budgetTitleLabel.color(LedgitColor.navigationTextGray)
            budgetLabel.color(LedgitColor.navigationTextGray)
            totalTripCostTitleLabel.color(LedgitColor.navigationTextGray)
            totalTripCostLabel.color(LedgitColor.navigationTextGray)
            estimatedTripCostTitleLabel.color(LedgitColor.navigationTextGray)
            estimatedTripCostLabel.color(LedgitColor.navigationTextGray)
        }
    }

    func setupLabels() {
        dayCostLabel.text(0.0.currencyFormat())
        remainingLabel.text(0.0.currencyFormat())
        averageLabel.text(0.0.currencyFormat())
        budgetLabel.text(0.0.currencyFormat())
        totalTripCostLabel.text(0.0.currencyFormat())
        estimatedTripCostLabel.text(0.0.currencyFormat())
    }

    func defaultChartSetup() {
        weeklyChart.dragEnabled = false
        weeklyChart.delegate = self
        weeklyChart.noDataTextAlignment = .center
        weeklyChart.noDataFont = .futuraMedium14
        weeklyChart.noDataTextColor = LedgitColor.coreBlue
        weeklyChart.pinchZoomEnabled = false
        weeklyChart.doubleTapToZoomEnabled = false
        weeklyChart.scaleXEnabled = false
        weeklyChart.scaleYEnabled = false
        weeklyChart.noDataText = Constants.ChartText.noWeeklyActivity
        weeklyChart.noDataTextAlignment = .center
    }

    private func setupStackViews() {
        budgetTitleLabel.text = "Daily budget"
    }

    func resetValues() {
        costToday = 0
        totalCost = 0
        averageCost = 0
        estimatedTotalCost = 0
        dates = []
        values = []
        amounts = [Double](repeating: 0, count: 7)
    }

    func setupLayout() {
        guard let presenter = presenter else { return }

        displayTipsIfNeeded(for: presenter.trip)

        resetValues()

        let dailyBudget: Double

        if presenter.trip.budgetSelection == .trip {
            dailyBudget = presenter.trip.budget / Double(presenter.trip.length)
        } else {
            dailyBudget = presenter.trip.budget
        }

        updateDefaultLabelValues(budgetAmount: dailyBudget)

        createWeeklyAmounts(using: presenter.entries)

        if !dates.isEmpty {
            averageCost = totalCost / Double(dates.count)
        }

        estimatedTotalCost = averageCost * Double(presenter.trip.length)

        updateLabels(dayAmount: costToday,
                     remainingAmount: dailyBudget - costToday,
                     averageAmount: averageCost,
                     totalTripAmount: totalCost,
                     estimatedTripAmount: estimatedTotalCost)

        guard !presenter.entries.isEmpty else {
            weeklyChart.clear()
            return
        }

        // Since we had to initialize an array with 7 items of 0.0
        // we have to check that at least one of them is not 0 so we
        // populate the chart. Otherwise, there is nothing to display
        // for "this week"
        guard !amounts.filter({ $0 != 0 }).isEmpty else { return }

        for (index, amount) in amounts.enumerated() {
            let entry = BarChartDataEntry(x: Double(index), y: amount)
            values.append(entry)
        }

        drawChart(with: values)
        setupLabelStyles()
    }

    private func createWeeklyAmounts(using entries: [LedgitEntry]) {
        entries.forEach { entry in
            !dates.contains(entry.date) ? dates.append(entry.date) : nil
            costToday += entry.date == Date().toString().toDate(withFormat: .full) ? entry.convertedCost : 0
            totalCost += entry.convertedCost

            /*
             * Chart is laid out with today being on the far right of the chart
             *
             *   -----   ----                     -----            -----
             *   -----   ----    -----            -----   ----     -----
             *   -----   ----    -----    -----   -----   ----     -----
             * |   0   |   1   |    2   |   3   |   4   |   5   |    6    |
             * |  Wed  |  Thur |   Fri  |  Sat  |  Sun  |  Mon  |  Today  |
             */

            if entry.date == (Date() - 6.days).toString().toDate(withFormat: .full) {
                amounts[0] += entry.convertedCost

            } else if entry.date == (Date() - 5.days).toString().toDate(withFormat: .full) {
                amounts[1] += entry.convertedCost

            } else if entry.date == (Date() - 4.days).toString().toDate(withFormat: .full) {
                amounts[2] += entry.convertedCost

            } else if entry.date == (Date() - 3.days).toString().toDate(withFormat: .full) {
                amounts[3] += entry.convertedCost

            } else if entry.date == (Date() - 2.days).toString().toDate(withFormat: .full) {
                amounts[4] += entry.convertedCost

            } else if entry.date == (Date() - 1.days).toString().toDate(withFormat: .full) {
                amounts[5] += entry.convertedCost

            } else if entry.date == Date().toString().toDate(withFormat: .full) {
                amounts[6] += entry.convertedCost
            }
        }
    }

    private func displayTipsIfNeeded(for trip: LedgitTrip) {
        guard trip.key != Constants.ProjectID.sample else { return }
        guard !UserDefaults.standard.bool(forKey: Constants.UserDefaultKeys.hasShowFirstWeeklyCellTips) else { return }
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultKeys.hasShowFirstWeeklyCellTips)

        let dayCostLabelTip = PopTip()
        dayCostLabelTip.style(PopStyle.default)
        dayCostLabelTip.shouldDismissOnTap = true
        dayCostLabelTip.show(text: "Checkout your running balance for today",
                             direction: .up, maxWidth: self.contentView.frame.width - 50,
                             in: dayCostLabel.superview!.superview!, from: dayCostLabel.frame, duration: 3)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let budgetLabelTip = PopTip()
            budgetLabelTip.style(PopStyle.default)
            dayCostLabelTip.shouldDismissOnTap = true
            budgetLabelTip.show(text: "This is your trip budget. This can be your entire budget or your daily budget.",
                                direction: .up, maxWidth: self.contentView.frame.width - 50,
                                in: self.budgetLabel.superview!.superview!, from: self.budgetLabel.superview!.frame, duration: 3)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            let remaingLabelTip = PopTip()
            remaingLabelTip.style(PopStyle.default)
            dayCostLabelTip.shouldDismissOnTap = true
            remaingLabelTip.show(text: "This is your remaining budget. If you selected daily, this is the amount you have left today to not go over.",
                                 direction: .up, maxWidth: self.contentView.frame.width - 50,
                                 in: self.remainingLabel.superview!.superview!, from: self.remainingLabel.superview!.frame, duration: 3)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
            let averageLabelTip = PopTip()
            averageLabelTip.style(PopStyle.default)
            dayCostLabelTip.shouldDismissOnTap = true
            averageLabelTip.show(text: "This is your average daily cost. It only counts the days you've actually expensed items.",
                                 direction: .up, maxWidth: self.contentView.frame.width - 50,
                                 in: self.averageLabel.superview!.superview!, from: self.averageLabel.superview!.frame, duration: 3)
        }
    }

    func updateDefaultLabelValues(budgetAmount: Double) {
        dayLabel.text(Date().toString(style: .full))
        budgetLabel.text(budgetAmount.currencyFormat())
        remainingLabel.text(budgetAmount.currencyFormat())
    }

    private func updateLabels(dayAmount: Double, remainingAmount: Double, averageAmount: Double, totalTripAmount: Double, estimatedTripAmount: Double) {
        totalTripCostLabel.text(totalTripAmount.currencyFormat())
        estimatedTripCostLabel.text(estimatedTripAmount.currencyFormat())

        dayCostLabel.text(dayAmount.currencyFormat())

        let averageDisplayAmount = averageAmount >= 0 ? averageAmount : (-1 * averageAmount)
        averageLabel.text(averageDisplayAmount.currencyFormat())

        let remainingDisplayAmount = remainingAmount >= 0 ? remainingAmount : (-1 * remainingAmount)
        let remainingDisplayColor = remainingAmount > 0 ? LedgitColor.coreGreen : LedgitColor.coreRed
        remainingLabel.color(remainingDisplayColor)
        remainingLabel.text(remainingDisplayAmount.currencyFormat())
    }

    fileprivate func drawChart(with values: [BarChartDataEntry]) {
        weeklyChart.animate(yAxisDuration: 1.5, easingOption: .easeInOutBack)

        let xFormat = BarChartXAxisFormatter(labels: weekdays)

        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.allowsFloats = false
        currencyFormatter.zeroSymbol = ""
        currencyFormatter.currencySymbol = LedgitUser.current.homeCurrency.symbol

        let xAxis: XAxis = weeklyChart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .futuraMedium10
        xAxis.drawGridLinesEnabled = false
        xAxis.granularity = 1.0 // only intervals of 1 day
        xAxis.labelCount = 7
        xAxis.valueFormatter = xFormat

        let leftAxis: YAxis = weeklyChart.leftAxis
        leftAxis.labelFont = .futuraMedium8
        leftAxis.labelPosition = .outsideChart
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: currencyFormatter)
        leftAxis.drawGridLinesEnabled = false

        let dataSet = BarChartDataSet(entries: values)
        dataSet.colors = [LedgitColor.coreBlue]

        let data = BarChartData(dataSet: dataSet)
        data.setValueFormatter(BarChartValueFormatter(formatter: currencyFormatter))
        data.setValueFont(.futuraMedium8)

        weeklyChart.data = data
        weeklyChart.rightAxis.enabled = false
        weeklyChart.leftAxis.enabled = false
        weeklyChart.legend.enabled = false
        weeklyChart.highlightPerTapEnabled = false
        weeklyChart.fitBars = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupLabelStyles()
    }
}

extension SummaryViewController {
    class BarChartXAxisFormatter: NSObject, AxisValueFormatter {
        var labels: [String] = []

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return labels[Int(value)]
        }

        init(labels: [String]) {
            super.init()
            self.labels = labels
        }
    }

    final class BarChartValueFormatter: ValueFormatter {
        private let formatter: NumberFormatter

        required init(formatter: NumberFormatter) {
            self.formatter = formatter
        }

        func stringForValue(_ value: Double, entry: Charts.ChartDataEntry, dataSetIndex: Int, viewPortHandler: Charts.ViewPortHandler?) -> String {
            if entry.y == 0 { return "" }

            return formatter.string(from: NSNumber(value: entry.y)) ?? ""
        }
    }
}
