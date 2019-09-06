//
//  CustomButton.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 9/2/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import UIKit

class CustomButton: UIView {
    
    enum ButtonState {
        case unselected
        case highlighted
    }
    
    enum TitleState {
        case primary
        case secondary
    }
    
    var buttonState: ButtonState = .unselected {
        didSet {
            switch buttonState {
            case .unselected:
                self.backgroundColor = unselectedColor
                expandButton()
            case .highlighted:
                self.backgroundColor = highlightedColor
                shrinkButton()
            }
        }
    }
    
    private var titleState: TitleState = .primary {
        didSet {
            updateAttributedTitleFor(type: titleState)
        }
    }
    
    public var primaryTitle: String = "PRIMARY" {
        didSet {
            updateAttributedTitleFor(type: .primary)
        }
    }
    
    public var secondaryTitle: String = "SECONDARY" {
        didSet {
            updateAttributedTitleFor(type: .secondary)
        }
    }
    
    public var titleFont: UIFont = UIFont(name: "HelveticaNeue", size: 11)! {
        didSet {
            updateAttributedTitleFor(type: titleState)
        }
    }
    
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.attributedText = createAttributedTitle(title: primaryTitle, font: titleFont, state: .primary)
        label.sizeToFit()
        label.center = self.center
        
        return label
    }()
    
    private func toggleLabelAttributedText() {
        switch titleState {
        case .primary:
            titleState = .secondary
        case .secondary:
            titleState = .primary
        }
    }
    
    var unselectedColor = UIColor(red:0.34, green:0.71, blue:0.38, alpha:1.0) {
        didSet {
            animateButtonColor(for: unselectedColor, animated: true)
        }
    }
    
    var highlightedColor = UIColor(red:0.24, green:0.50, blue:0.26, alpha:1.0) {
        didSet {
            animateButtonColor(for: highlightedColor, animated: true)
        }
    }
    
    
    var onTap: () -> () = {}
    
    var touchHasStayedInButton = false {
        didSet {
            buttonState = touchHasStayedInButton ? .highlighted : .unselected
            print("🌵 touchHasStayedInButton", touchHasStayedInButton)
        }
    }
    
    var tapRecognizer: UITapGestureRecognizer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = unselectedColor
        
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20).isActive = true
        label.topAnchor.constraint(equalTo: self.topAnchor, constant: 5).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5).isActive = true
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(gestureRecognizer:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        self.addGestureRecognizer(tapRecognizer)

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc private func didTap(gestureRecognizer: UITapGestureRecognizer) {
        toggleLabelAttributedText()
        onTap()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first {
            print(self.frame)
            print(touch.preciseLocation(in: self.superview))
            print(self.frame.contains(touch.preciseLocation(in: self.superview)))
            touchHasStayedInButton = self.frame.contains(touch.preciseLocation(in: self.superview))
            print("😫", touchHasStayedInButton)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesMoved(touches, with: event)
        
        guard touchHasStayedInButton == true else { return }
        
        if let touch = touches.first {
            if self.frame.contains(touch.preciseLocation(in: self.superview)) == false {
                touchHasStayedInButton = false
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard touchHasStayedInButton == true else { return }
        
        if let touch = touches.first {
            if self.frame.contains(touch.preciseLocation(in: self.superview)) == false {
                touchHasStayedInButton = false
            } else {
                // reset button's state since it will be tapped
                buttonState = .unselected
                //didTap()
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        guard touchHasStayedInButton == true else { return }
        
        if let touch = touches.first {
            if self.frame.contains(touch.preciseLocation(in: self.superview)) == false {
                touchHasStayedInButton = false
            } else {
                // reset button's state since it will be tapped
                buttonState = .unselected
                //didTap()
            }
        }
    }
    
    // what is the point of this?
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event)
        
        return true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setRoundedCorners()
    }
    
    private func setRoundedCorners() {
        let bezierPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.bounds.width / 2 )
        let maskLayer = CAShapeLayer()
        maskLayer.path = bezierPath.cgPath
        layer.mask = maskLayer
    }
    
    private func createAttributedTitle(title: String, font: UIFont, state: TitleState) -> NSMutableAttributedString {
        let titleTextColor = state == .primary ? UIColor.white : UIColor.white
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: titleTextColor,
            .kern: 1.50,
            .paragraphStyle: { () -> NSParagraphStyle in
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                return paragraphStyle
            }()
        ]
        let attributedButtonTitle = NSMutableAttributedString(string: title, attributes: attributes)
        return attributedButtonTitle
    }
    
    private func updateAttributedTitleFor(type: TitleState) {
        let newTitle = type == .primary ? primaryTitle : secondaryTitle
        let attributedTitle = createAttributedTitle(title: newTitle, font: titleFont, state: type)

        self.label.attributedText = attributedTitle
        self.label.textAlignment = .center
        self.label.sizeToFit()
        self.setNeedsLayout()
        
    }
    
    func shrinkButton() {
        UIView.animate(withDuration: 0.2) {
            self.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
        }
    }
    
    func expandButton() {
        UIView.animate(withDuration: 0.2) {
            self.transform = .identity
        }
    }
    
    private func animateButtonColor(for color: UIColor, animated: Bool) {
        guard animated == true else { return }
        
        switch buttonState {
        case .unselected:
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = color
            }
        case .highlighted:
            break
        }
    }
    

}
