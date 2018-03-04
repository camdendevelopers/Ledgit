//
//  CurrencyTableViewCell.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 11/12/17.
//  Copyright © 2017 Camden Developers. All rights reserved.
//

import UIKit

class CurrencyTableViewCell: UITableViewCell {
    @IBOutlet weak var currencyImageView: UIImageView!
    @IBOutlet weak var currencyImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!

    func configure(with currency: Currency) {
        if ResourceManager.shared.retrievedFlags {
            currencyImageView.image = UIImage(named: currency.flagCode,
                                              in: ResourceManager.shared.bundle,
                                              compatibleWith: nil)
        } else {
            currencyImageViewWidthConstraint.constant = 0
        }
        
        nameLabel.text(currency.name)
        codeLabel.text(currency.code)
    }
}
