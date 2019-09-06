//
//  CardView.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 9/5/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import UIKit

class CardView: UIView {
    
    let containerView = UIView()
    let cornerRadius: CGFloat = 6.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        
        layer.backgroundColor = UIColor.clear.cgColor
        layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2.0)
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 8.0
        
        containerView.layer.cornerRadius = cornerRadius
        containerView.layer.masksToBounds = true
        containerView.backgroundColor = .white
        
        addSubview(containerView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}
