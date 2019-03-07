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

    var averageCost: Double = 0
    var costToday: Double = 0
    var totalCost: Double = 0
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

    func setupLabels() {
        dayCostLabel.color(LedgitColor.navigationTextGray)
        remainingLabel.color(LedgitColor.navigationTextGray)
        averageLabel.color(LedgitColor.navigationTextGray)
        budgetLabel.color(LedgitColor.navigationTextGray)
        dayCostLabel.text(0.0.currencyFormat())
        remainingLabel.text(0.0.currencyFormat())
        averageLabel.text(0.0.currencyFormat())
        budgetLabel.text(0.0.currencyFormat())
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
        dates = []
        values = []
        amounts = [Double](repeating: 0, count: 7)
    }

    func setupLayout() {
        guard let presenter = presenter else { return }

        displayTipsIfNeeded(for: presenter.trip)

        resetValues()

        updateDefaultLabelValues(budgetAmount: presenter.trip.budget)

        guard !presenter.entries.isEmpty else {
            weeklyChart.clear()
            return
        }

        createWeeklyAmounts(using: presenter.entries)

        averageCost = totalCost / Double(dates.count)

        updateLabels(dayAmount: costToday,
                     remainingAmount: presenter.trip.budget - costToday,
                     averageAmount: averageCost)

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
        dayCostLabelTip.show(text: "Checkout your running balance for today",
                             direction: .up, maxWidth: self.contentView.frame.width - 50,
                             in: dayCostLabel.superview!, from: dayCostLabel.frame, duration: 3)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let budgetLabelTip = PopTip()
            budgetLabelTip.style(PopStyle.default)
            budgetLabelTip.show(text: "This is your trip budget. This can be your entire budget or your daily budget.",
                                direction: .up, maxWidth: self.contentView.frame.width - 50,
                                in: self.budgetLabel.superview!.superview!, from: self.budgetLabel.superview!.frame, duration: 3)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            let remaingLabelTip = PopTip()
            remaingLabelTip.style(PopStyle.default)
            remaingLabelTip.show(text: "This is your remaining budget. If you selected daily, this is the amount you have left today to not go over.",
                                 direction: .up, maxWidth: self.contentView.frame.width - 50,
                                 in: self.remainingLabel.superview!.superview!, from: self.remainingLabel.superview!.frame, duration: 3)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
            let averageLabelTip = PopTip()
            averageLabelTip.style(PopStyle.default)
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

    private func updateLabels(dayAmount: Double, remainingAmount: Double, averageAmount: Double) {
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

        let dataFormat = NumberFormatter()
        dataFormat.numberStyle = .currency
        dataFormat.allowsFloats = false
        dataFormat.zeroSymbol = ""
        dataFormat.currencySymbol = LedgitUser.current.homeCurrency.symbol
        let dataFormatter = DefaultValueFormatter(formatter: dataFormat)

        let xAxis: XAxis = weeklyChart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .futuraMedium10
        xAxis.labelTextColor = LedgitColor.navigationTextGray
        xAxis.drawGridLinesEnabled = false
        xAxis.granularity = 1.0 // only intervals of 1 day
        xAxis.labelCount = 7
        xAxis.valueFormatter = xFormat

        let leftAxis: YAxis = weeklyChart.leftAxis
        leftAxis.labelTextColor = LedgitColor.navigationTextGray
        leftAxis.labelFont = .futuraMedium8
        leftAxis.labelPosition = .outsideChart
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: dataFormat)
        leftAxis.drawGridLinesEnabled = false
        leftAxis.gridColor = LedgitColor.navigationBarGray
        leftAxis.gridLineWidth = 1.0

        let dataSet = BarChartDataSet(values: values, label: nil)
        dataSet.colors = [LedgitColor.coreBlue]

        let data = BarChartData(dataSet: dataSet)
        data.setValueFormatter(dataFormatter)
        data.setValueFont(.futuraMedium8)
        data.setValueTextColor(LedgitColor.coreBlue)

        weeklyChart.data = data
        weeklyChart.rightAxis.enabled = false
        weeklyChart.leftAxis.enabled = false
        weeklyChart.legend.enabled = false
        weeklyChart.chartDescription = nil
        weeklyChart.highlightPerTapEnabled = false
    }
}

extension SummaryViewController {
    class BarChartXAxisFormatter: NSObject, IAxisValueFormatter {
        var labels: [String] = []

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return labels[Int(value)]
        }

        init(labels: [String]) {
            super.init()
            self.labels = labels
        }
    }
}
