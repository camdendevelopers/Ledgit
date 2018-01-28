//
//  HistoryCollectionViewCell.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 8/18/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit
import BetterSegmentedControl
import SwiftDate

protocol DayTableCellDelegate: class {
    func selected(entry: LedgitEntry)
}

class HistoryCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var segmentedControl: BetterSegmentedControl!
    @IBOutlet weak var cityTableView: UITableView!
    @IBOutlet weak var dayTableView: UITableView!
    weak var delegate: DayTableCellDelegate?
    
    var dateEntries: [DateSection] = []
    var cityEntries: [CitySection] = []
    let headerHeight: CGFloat = 25
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupTableViews()
        setupSegmentedControl()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
         contentView.layer.cornerRadius = 10
         contentView.layer.borderWidth = 1
         contentView.layer.borderColor = UIColor.clear.cgColor
         contentView.layer.masksToBounds = true
         
         layer.cornerRadius = 10
         layer.shadowColor = UIColor.black.cgColor
         layer.shadowOffset = CGSize(width:0,height: 2)
         layer.shadowRadius = 4
         layer.shadowOpacity = 0.10
         layer.masksToBounds = false
         layer.shadowPath = UIBezierPath(roundedRect:bounds, cornerRadius:contentView.layer.cornerRadius).cgPath
    }
    
    func setupTableViews(){
        cityTableView.delegate = self
        cityTableView.dataSource = self
        
        dayTableView.delegate = self
        dayTableView.dataSource = self
    }
    
    func setupSegmentedControl(){
        segmentedControl.layer.borderWidth = 1
        segmentedControl.layer.borderColor = UIColor.ledgitBlue.cgColor
        segmentedControl.titles = ["Date", "City"]
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
    }
    
    @objc func segmentedControlChanged(control: BetterSegmentedControl){
        switch control.index {
        case 0:
            cityTableView.flipTransition(with: dayTableView)
        default:
            dayTableView.flipTransition(with: cityTableView, isReverse: true)
        }
    }
    
    func setup(with presenter:TripDetailPresenter) {
        let data = presenter.entries
        guard !data.isEmpty else { return }
        
        dateEntries = []
        cityEntries = []
    
        for item in data {
            if let index = dateEntries.index(where: { $0.date.isInSameDayOf(date: item.date) }) {
                dateEntries[index].entries.append(item)
            } else {
                
                let newSection = DateSection(date: item.date, entries: [item])
                dateEntries.append(newSection)
            }
            
            if let index = cityEntries.index(where: {$0.location == item.location}) {
                cityEntries[index].amount += item.convertedCost
                
            } else {
                let newSection = CitySection(location: item.location, amount: item.convertedCost)
                cityEntries.append(newSection)
            }
        }
    
        cityTableView.reloadData()
        dayTableView.reloadData()
    }
}

extension HistoryCollectionViewCell: UITableViewDelegate, UITableViewDataSource{
    
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
            
            let view = UIView()
            let dateSection = dateEntries[section]
            view.backgroundColor = .ledgitNavigationBarGray
        
            let label = UILabel(frame: CGRect(x: 15,
                                              y: 0,
                                              width: dayTableView.frame.width,
                                              height: headerHeight))
            label.text = dateSection.date.toString(style: .medium)
            label.font = .futuraMedium10
            label.textColor = .ledgitNavigationTextGray
            
            view.addSubview(label)
            return view
            
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case dayTableView:
            return dateEntries[section].entries.count
        default:
            return cityEntries.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case dayTableView:
            let cell = dayTableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifiers.date, for: indexPath) as! DateTableViewCell
            let entry = dateEntries[indexPath.section].entries[indexPath.row]
            cell.setup(with: entry)
           
            return cell
        default:
            let cell = cityTableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifiers.city, for: indexPath) as! CityTableViewCell
            let section = cityEntries[indexPath.row]
            cell.setup(with: section)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView == dayTableView else { return }
        let entry = dateEntries[indexPath.section].entries[indexPath.row]
        delegate?.selected(entry: entry)
    }
}
