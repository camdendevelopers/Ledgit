//
//  CollapsibleDateHeaderView.swift
//  Ledgit
//
//  Created by Marcos Ortiz on 1/28/18.
//  Copyright © 2018 Camden Developers. All rights reserved.
//

import UIKit

protocol CollapsibleDateHeaderViewDelegate: AnyObject {
    func toggleSection(_ header: CollapsibleDateHeaderView, section: Int)
}

class CollapsibleDateHeaderView: UITableViewHeaderFooterView {
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let scale: CGFloat = 0.35
    let headerPadding: CGFloat = 15
    weak var delegate: CollapsibleDateHeaderViewDelegate?
    var section: Int = 0

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupLayout()
        setupElements()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
        setupElements()
    }

    func setupLayout() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        imageView.image(#imageLiteral(resourceName: "disclosure-icon"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: scale).isActive = true
        imageView.widthAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: scale).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -headerPadding).isActive = true
        imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true

        titleLabel.font(.futuraMedium14)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: headerPadding).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(headerTapped)))
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupElements()
    }

    func setupElements() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        if #available(iOS 13.0, *) {
            contentView.backgroundColor = isDarkMode ? .systemGray4 : .systemGray5
            titleLabel.color(isDarkMode ? .white : LedgitColor.navigationTextGray)
        } else {

            contentView.backgroundColor = LedgitColor.navigationBarGray
            titleLabel.color(LedgitColor.navigationTextGray)
        }
    }

    @objc func headerTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let cell = gestureRecognizer.view as? CollapsibleDateHeaderView else { return }
        delegate?.toggleSection(self, section: cell.section)
    }

    func setCollapsed(_ collapsed: Bool) {
        UIView.animate(withDuration: 0.75) {
            self.imageView.image(collapsed ? #imageLiteral(resourceName: "disclosure-icon") : #imageLiteral(resourceName: "disclosure-down-icon"))
        }
    }
}
