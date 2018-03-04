//
//  UITableView+Content.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 3/4/18.
//  Copyright © 2018 Camden Developers. All rights reserved.
//

import UIKit

extension UITableView {
    func lastRow(at section: Int) -> Int{
        return self.numberOfRows(inSection: section) - 1
    }
}
