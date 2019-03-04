//
//  CategoryViewController.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 2/28/19.
//  Copyright © 2019 Camden Developers. All rights reserved.
//

import UIKit
import Charts

class CategoryViewController: UIViewController, ChartViewDelegate {
    @IBOutlet var contentView: UIView!
    @IBOutlet var pieChart: PieChartView!
    @IBOutlet var displayButton: UIButton!
    
    weak var presenter: TripDetailPresenter?
    var needsLayout: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupChart()
        setupButton()
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
    }
    
    func setupButton(){
        displayButton.roundedCorners(radius: 15)
        displayButton.color(LedgitColor.coreBlue)
        displayButton.setTitleColor(.white, for: .normal)
    }
    
    func setupChart() {
        pieChart.delegate = self
        pieChart.noDataText = Constants.chartText.empty
        pieChart.noDataFont = .futuraMedium14
        pieChart.noDataTextColor = LedgitColor.coreBlue
    }
    
    func setupLayout() {
        guard let presenter = presenter else { return }
        
        var categories: [String: Double] = [:]
        var values: [PieChartDataEntry] = []
        
        guard !presenter.entries.isEmpty else {
            pieChart.clear()
            return
        }
        
        for item in presenter.entries {
            if categories.keys.contains(item.category) {
                categories[item.category]! += item.convertedCost
            } else {
                categories[item.category] = item.convertedCost
            }
        }
        
        for item in categories {
            let entry = PieChartDataEntry(value: item.value, label: item.key)
            values.append(entry)
        }
        
        drawChart(with: values)
    }
    
    fileprivate func drawChart(with values: [PieChartDataEntry]) {
        let legend: Legend = pieChart.legend
        legend.form = .circle
        legend.formSize = 12
        legend.horizontalAlignment = .center
        legend.verticalAlignment = .bottom
        legend.orientation = .horizontal
        legend.xEntrySpace = 20.0
        legend.yEntrySpace = 8.0
        legend.yOffset = 10.0
        legend.textColor = LedgitColor.navigationTextGray
        legend.font = .futuraMedium12

        pieChart.drawEntryLabelsEnabled = false
        pieChart.chartDescription = nil
        pieChart.usePercentValuesEnabled = true
        pieChart.drawSlicesUnderHoleEnabled = false
        pieChart.holeRadiusPercent = 0.6
        pieChart.transparentCircleRadiusPercent = 1
        pieChart.drawCenterTextEnabled = true
        pieChart.drawHoleEnabled = true
        pieChart.rotationAngle = 0.0
        pieChart.rotationEnabled = false
        pieChart.highlightPerTapEnabled = false
        pieChart.animate(xAxisDuration: 1.4, easingOption: .easeInOutBack)
        
        let dataSet = PieChartDataSet(values: values, label: nil)
        dataSet.yValuePosition = .insideSlice
        dataSet.drawIconsEnabled = false
        dataSet.sliceSpace = 2.0
        dataSet.entryLabelColor = .white
        dataSet.colors = [LedgitColor.pieChartLightPurple,
                          LedgitColor.pieChartDarkGray,
                          LedgitColor.pieChartBlue1,
                          LedgitColor.pieChartOrange,
                          LedgitColor.pieChartRed,
                          LedgitColor.pieChartBlue3,
                          LedgitColor.pieChartDarkPurple,
                          LedgitColor.pieChartBlue2,
                          LedgitColor.pieChartBlue4,
                          LedgitColor.pieChartBlue6,
                          LedgitColor.pieChartGreen,
                          LedgitColor.pieChartBlue5]
        
        let data = PieChartData(dataSet: dataSet)
        let format = NumberFormatter()
        format.numberStyle = .percent
        format.maximumFractionDigits = 2
        format.multiplier = 1.0
        format.percentSymbol = "%"
        
        let formatter = DefaultValueFormatter(formatter: format)
        data.setValueFormatter(formatter)
        data.setValueFont(.futuraMedium12)
        data.setValueTextColor(.white)
        
        pieChart.data = data
        pieChart.highlightValues(nil)
    }
    
    @IBAction func displayButtonPressed(_ sender: Any) {
        guard let title = displayButton.currentTitle else { return }
        
        switch title {
        case "%":
            let format = NumberFormatter()
            format.numberStyle = .percent
            format.maximumFractionDigits = 2
            format.multiplier = 1.0
            format.percentSymbol = "%"
            let formatter = DefaultValueFormatter(formatter: format)
            
            pieChart.data?.setValueFormatter(formatter)
            pieChart.usePercentValuesEnabled = true
            displayButton.setTitle("$", for: .normal)
        default:
            let format = NumberFormatter()
            format.numberStyle = .currency
            format.currencySymbol = LedgitUser.current.homeCurrency.symbol
            let formatter = DefaultValueFormatter(formatter: format)
            
            pieChart.data?.setValueFormatter(formatter)
            pieChart.usePercentValuesEnabled = false
            displayButton.setTitle("%", for: .normal)
        }
    }
}
