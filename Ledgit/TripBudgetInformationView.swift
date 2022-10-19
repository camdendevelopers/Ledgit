//
//  TripBudgetInformationView.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 2/11/18.
//  Copyright © 2018 Camden Developers. All rights reserved.
//

import UIKit

class TripBudgetInformationView: UIView {
    var titleLabel = UILabel()

    private var titleText = ""

    init() {
        super.init(frame: .zero)
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout() {
        backgroundColor = LedgitColor.coreBlue

        titleLabel.numberOfLines = 0
        titleLabel.textColor = .white
        titleLabel.font = .futuraBold13
        // titleLabel.textAlignment = .center

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
    }

    func configure(with amountText: String, selection: BudgetSelection, tripLength: Int) {
        let budgetAmount = amountText
            .replacingOccurrences(of: LedgitUser.current.homeCurrency.symbol, with: "")
            .replacingOccurrences(of: ",", with: "")

        guard let amount = Double(budgetAmount) else { return }

        if selection == .daily {
            let tripBudget = amount * Double(tripLength)
            let tripBudgetText = String(tripBudget).currencyFormat()

            titleLabel.text("Based on your daily budget of \(amountText), you'll likely spend \(tripBudgetText) on your \(tripLength) day long trip.")

        } else if selection == .trip {
            let dailyBudget = amount / Double(tripLength)
            let dailyBudgetText = String(dailyBudget).currencyFormat()

            titleLabel.text("Based on your trip budget of \(amountText), you'll likely spend \(dailyBudgetText)/day on your \(tripLength) day long trip.")
        }
    }
}
