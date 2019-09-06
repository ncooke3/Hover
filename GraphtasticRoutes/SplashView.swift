//
//  SplashView.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 9/2/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import UIKit
import Lottie

class SplashView: UIView {
    
    var splashTapped: () -> () = {}
    var tapRecognizer: UITapGestureRecognizer!
    
    lazy var hoverLabel: UILabel = {
        let label = UILabel()
        let labelFont = UIFont(name: "Rationale-Regular", size: 72)!
        let labelColor = UIColor.white
        let labelLetterSpacing = 1.50
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: labelColor,
            .kern: labelLetterSpacing
        ]
        let attributedLabelTitle = NSMutableAttributedString(string: "hover", attributes: labelAttributes)
        label.attributedText = attributedLabelTitle
        label.sizeToFit()
        return label
    }()
    
    lazy var tapLabel: UILabel = {
        let label = UILabel()
        let labelFont = UIFont(name: "Rationale-Regular", size: 12)!
        let labelColor = UIColor.white
        let labelLetterSpacing = 1.25
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: labelColor,
            .kern: labelLetterSpacing
        ]
        let attributedLabelTitle = NSMutableAttributedString(string: "tap here to get started", attributes: labelAttributes)
        label.attributedText = attributedLabelTitle
        label.sizeToFit()
        return label
    }()
    
    lazy var hoverLabelYConstant = NSLayoutConstraint()
    
    lazy var circleView = UIView()
    
    lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    
    lazy var firstDroneAnimation: AnimationView = {
        let animationView = AnimationView()
        animationView.animation = Animation.named("drone_lottie")
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        return animationView
    }()
    
    lazy var loopingDroneAnimation: AnimationView = {
        let animationView = AnimationView()
        animationView.animation = Animation.named("drone_lottie")
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        return animationView
    }()
    
    
    lazy var earthAnimation: AnimationView = {
        let animationView = AnimationView()
        animationView.animation = Animation.named("earth_lottie")
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
        return animationView
    }()
    
    lazy var earthAnimationYConstant = NSLayoutConstraint()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    private func setupView() {
        backgroundColor = Colors.custom(hexString: "#3f87dd", alpha: 1.0).value // #3f87ddff is pretty
        addSubview(hoverLabel)
        addSubview(tapLabel)
        addSubview(circleView)
        addSubview(bottomView)
        addSubview(firstDroneAnimation)
        addSubview(loopingDroneAnimation)
        addSubview(earthAnimation)
        setupLayout()
        handleDroneAnimations()
        
        
        tapRecognizer = UITapGestureRecognizer(target: self.frame, action: #selector(didTap))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tapRecognizer)
        
        
        
        
    }
    
    @objc private func didTap() {
        splashTapped()
    }
    
    private func setupLayout() {
        hoverLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hoverLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)])
        
        hoverLabelYConstant = hoverLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -150)
        hoverLabelYConstant.isActive = true
        
        tapLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tapLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            tapLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -100)])  // comment to hover!
            //tapLabel.topAnchor.constraint(equalTo: hoverLabel.bottomAnchor, constant: 10)]) // uncomment to hover!
        
        let circleFrame = CGRect(x: 0, y: 0, width: self.frame.width + 100, height: self.frame.width + 100)
        circleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: -5),
            circleView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 225),
            circleView.heightAnchor.constraint(equalToConstant: self.frame.width + 100),
            circleView.widthAnchor.constraint(equalToConstant: self.frame.width + 105)])
        
        let circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(ovalIn: circleFrame).cgPath
        circleLayer.fillColor = UIColor.white.cgColor
        circleView.layer.addSublayer(circleLayer)
        
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            bottomView.widthAnchor.constraint(equalTo: self.widthAnchor),
            bottomView.heightAnchor.constraint(equalToConstant: 200)])
        
        firstDroneAnimation.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            firstDroneAnimation.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            firstDroneAnimation.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -250),
            firstDroneAnimation.widthAnchor.constraint(equalToConstant: self.frame.width),
            firstDroneAnimation.heightAnchor.constraint(equalToConstant: self.frame.width)])
        
        loopingDroneAnimation.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loopingDroneAnimation.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            loopingDroneAnimation.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -250),
            loopingDroneAnimation.widthAnchor.constraint(equalToConstant: self.frame.width),
            loopingDroneAnimation.heightAnchor.constraint(equalToConstant: self.frame.width)])
        
        earthAnimation.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            earthAnimation.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            earthAnimation.widthAnchor.constraint(equalToConstant: 315),
            earthAnimation.heightAnchor.constraint(equalToConstant: 315)])
        earthAnimationYConstant = earthAnimation.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -37)
        earthAnimationYConstant.isActive = true
        
        // TODO: Add shadow under earth
    }
    
    private func animateHoverLabel() {
        self.layoutIfNeeded()
        hoverLabelYConstant.constant = -147
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func animateEarthAnimation() {
        self.layoutIfNeeded()
        earthAnimationYConstant.constant = -30
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func handleDroneAnimations() {
        firstDroneAnimation.play { (_) in
            self.loopingDroneAnimation.play()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        animateHoverLabel()
        animateEarthAnimation()
    }
}
