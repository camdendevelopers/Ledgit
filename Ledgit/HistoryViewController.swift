//
//  HistoryViewController.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 2/28/19.
//  Copyright © 2019 Camden Developers. All rights reserved.
//

import UIKit
import BetterSegmentedControl
import SwiftDate

protocol DayTableCellDelegate: AnyObject {
    func selected(entry: LedgitEntry, at point: CGPoint)
}

class HistoryViewController: UIViewController {
    @IBOutlet var contentView: UIView!
    @IBOutlet var segmentedControl: BetterSegmentedControl!
    @IBOutlet var cityTableView: UITableView!
    @IBOutlet var dayTableView: UITableView!

    weak var delegate: DayTableCellDelegate?
    weak var presenter: TripDetailPresenter?
    var needsLayout: Bool = true

    var dateEntries: [DateSection] = []
    var cityEntries: [CitySection] = []
    let headerHeight: CGFloat = 30

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTableViews()
        setupSegmentedControl()
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

    func setupTableViews() {
        cityTableView.delegate = self
        cityTableView.dataSource = self

        dayTableView.delegate = self
        dayTableView.dataSource = self
    }

    func setupSegmentedControl() {
        let dateSegment = LabelSegment(text: "Date", normalFont: .futuraMedium16, normalTextColor: LedgitColor.coreBlue, selectedFont: .futuraMedium16, selectedTextColor: .white)
        let citySegment = LabelSegment(text: "City", normalFont: .futuraMedium16, normalTextColor: LedgitColor.coreBlue, selectedFont: .futuraMedium16, selectedTextColor: .white)
        segmentedControl.layer.borderWidth = 1
        segmentedControl.layer.borderColor = LedgitColor.coreBlue.cgColor
        segmentedControl.segments = [dateSegment, citySegment]
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
    }

    @objc func segmentedControlChanged(control: BetterSegmentedControl) {
        switch control.index {
        case 0:
            cityTableView.flipTransition(with: dayTableView)
        default:
            dayTableView.flipTransition(with: cityTableView, isReverse: true)
        }
    }

    func setupLayout() {
        guard let presenter = presenter else { return }

        dateEntries = []
        cityEntries = []

        for item in presenter.entries {

            if let index = dateEntries.firstIndex(where: { $0.date.compare(.isSameDay(item.date)) }) {
                dateEntries[index].entries.append(item)
            } else {

                let newSection = DateSection(date: item.date, entries: [item], collapsed: false)
                dateEntries.append(newSection)
            }

            if let index = cityEntries.firstIndex(where: {$0.location == item.location}) {
                cityEntries[index].amount += item.convertedCost

            } else {
                let newSection = CitySection(location: item.location, amount: item.convertedCost)
                cityEntries.append(newSection)
            }
        }

        dateEntries = dateEntries.sorted { $0.date > $1.date }

        cityTableView.reloadData()
        dayTableView.reloadData()
    }
}

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        switch tableView {
        case dayTableView:
            return dateEntries.count
        default:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch tableView {
        case dayTableView:
            return headerHeight
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        switch tableView {

        case dayTableView:
            guard !dateEntries.isEmpty else { return nil }
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? CollapsibleDateHeaderView ?? CollapsibleDateHeaderView(reuseIdentifier: "header")
            header.section = section
            header.setCollapsed(dateEntries[section].collapsed)
            header.titleLabel.text(dateEntries[section].date.toString(style: .medium))
            header.delegate = self

            return header

        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case dayTableView:
            return dateEntries[section].collapsed ? 0 : dateEntries[section].entries.count
        default:
            return cityEntries.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case dayTableView:
            let cell = dayTableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifiers.date, for: indexPath) as! DateTableViewCell // swiftlint:disable:this force_cast
            let entry = dateEntries[indexPath.section].entries[indexPath.row]
            cell.setup(with: entry)

            return cell
        default:
            let cell = cityTableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifiers.city, for: indexPath) as! CityTableViewCell // swiftlint:disable:this force_cast
            let section = cityEntries[indexPath.row]
            cell.setup(with: section)

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView == dayTableView else { return }
        let entry = dateEntries[indexPath.section].entries[indexPath.row]

        let rectOfRow = tableView.rectForRow(at: indexPath)
        let rectInSuperview = tableView.convert(rectOfRow, to: (delegate as? UIViewController)?.view)
        let center = CGPoint(x: rectInSuperview.midX, y: rectInSuperview.midY)
        delegate?.selected(entry: entry, at: center)
    }
}

extension HistoryViewController: CollapsibleDateHeaderViewDelegate {
    func toggleSection(_ header: CollapsibleDateHeaderView, section: Int) {
        let collapsed = !dateEntries[section].collapsed
        let sectionToReload = IndexSet(integer: section)

        dateEntries[section].collapsed = collapsed
        header.setCollapsed(collapsed)
        dayTableView.reloadSections(sectionToReload, with: .automatic)
    }
}
