//
//  ViewController.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 8/30/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import UIKit
import MapKit
import Lottie

extension UISpringTimingParameters {
    
    /// A design-friendly way to create a spring timing curve.
    ///
    /// - Parameters:
    ///   - damping: The 'bounciness' of the animation. Value must be between 0 and 1.
    ///   - response: The 'speed' of the animation.
    ///   - initialVelocity: The vector describing the starting motion of the property. Optional, default is `.zero`.
    public convenience init(damping: CGFloat, response: CGFloat, initialVelocity: CGVector = .zero) {
        let stiffness = pow(2 * .pi / response, 2)
        let damp = 4 * .pi * damping / response
        self.init(mass: 1, stiffness: stiffness, damping: damp, initialVelocity: initialVelocity)
    }
    
}


class InstantPanGestureRecognizer: UIPanGestureRecognizer {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.state = .began
    }
    
    
}

extension ViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        print("print frames")
        print(button.frame)
        print(northAmericaButton.frame)
        print(globalButton.frame)
        print(georgiaTechButton.frame)
        
        let buttonContainsTouch = button.frame.contains(touch.location(in: momentumView))
        let americaButtonContainsTouch = northAmericaButton.frame.contains(touch.location(in: momentumView))
        let globalButtonContainsTouch = globalButton.frame.contains(touch.location(in: momentumView))
        let georgiaTechButtonContainsTouch = georgiaTechButton.frame.contains(touch.location(in: momentumView))
            print(georgiaTechButton.buttonState)
        print("Gesture Recognized", buttonContainsTouch, americaButtonContainsTouch, globalButtonContainsTouch, georgiaTechButtonContainsTouch)
        if buttonContainsTouch || americaButtonContainsTouch || globalButtonContainsTouch || georgiaTechButtonContainsTouch {
            if gestureRecognizer == panRecognizer {
                return false
            }
        }
        print("marked")
        return true

    }
    
    
    
}


class ViewController: UIViewController {
    
    @objc private func panned(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startAnimationIfNeeded()
            animator.pauseAnimation()
            animationProgress = animator.fractionComplete
        case .changed:
            var fraction = -recognizer.translation(in: momentumView).y / closedTransform.ty
            if isOpen { fraction *= -1 }
            if animator.isReversed { fraction *= -1 }
            animator.fractionComplete = fraction + animationProgress
        // todo: rubberbanding
        case .ended, .cancelled:
            let yVelocity = recognizer.velocity(in: momentumView).y
            let shouldClose = yVelocity > 0 // todo: should use projection instead
            if yVelocity == 0 {
                animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                break
            }
            if isOpen {
                if !shouldClose && !animator.isReversed { animator.isReversed.toggle() }
                if shouldClose && animator.isReversed { animator.isReversed.toggle() }
            } else {
                if shouldClose && !animator.isReversed { animator.isReversed.toggle() }
                if !shouldClose && animator.isReversed { animator.isReversed.toggle() }
            }
            let fractionRemaining = 1 - animator.fractionComplete
            let distanceRemaining = fractionRemaining * closedTransform.ty
            if distanceRemaining == 0 {
                animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                break
            }
            let relativeVelocity = min(abs(yVelocity) / distanceRemaining, 30)
            let timingParameters = UISpringTimingParameters(damping: 0.8, response: 0.3, initialVelocity: CGVector(dx: relativeVelocity, dy: relativeVelocity))
            let preferredDuration = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters).duration
            let durationFactor = CGFloat(preferredDuration / animator.duration)
            animator.continueAnimation(withTimingParameters: timingParameters, durationFactor: durationFactor)
        default: break
        }
    }
    
    private func startAnimationIfNeeded() {
        if animator.isRunning { return }
        let timingParameters = UISpringTimingParameters(damping: 1, response: 0.4)
        animator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
        animator.addAnimations {
            self.momentumView.transform = self.isOpen ? self.closedTransform : .identity
        }
        animator.addCompletion { position in
            if position == .end { self.isOpen.toggle() }
        }
        animator.startAnimation()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    lazy var splashView = SplashView(frame: self.view.frame)

    var mapView = MKMapView()
    var locationGraph: Graph!
    
    var flightpathPolyline = MKGeodesicPolyline()
    var planeAnnotation: MKPointAnnotation!
    var planeAnnotationPosition = 0
    
    var userInputToggle: Bool! {
        didSet {
            button.isUserInteractionEnabled = userInputToggle
        }
    }
    
    var startVertex: Vertex? {
        didSet {
            userInputToggle = startVertex != nil && goalVertex != nil
            
        }
    }
    
    var goalVertex: Vertex? {
        didSet {
            userInputToggle = startVertex != nil && goalVertex != nil
        }
    }
    
    lazy var northAmericaButton = CustomButton()
    lazy var globalButton = CustomButton()
    lazy var georgiaTechButton = CustomButton()
    
    lazy var button: CustomButton = {
        let button = CustomButton()
        button.isUserInteractionEnabled = false

        return button
    }()

    lazy var graphTypeLabel: UILabel = {
        let label = UILabel()
        label.attributedText = createAttributedTitle(title: "Graph Type", font: UIFont(name: "Rationale-Regular", size: 25)!)
        label.numberOfLines = 1
        label.sizeToFit()
        return label
    }()
    
    lazy var sourceLocationLabel: UILabel = {
        let label = UILabel()
        label.attributedText = createAttributedTitle(title: "New York", font: UIFont(name: "Rationale-Regular", size: 35)!)
        // centered?
        label.numberOfLines = 1
        label.sizeToFit()
        return label
    }()
    
    lazy var destinationLocationLabel: UILabel = {
        let label = UILabel()
        label.attributedText = createAttributedTitle(title: "London", font: UIFont(name: "Rationale-Regular", size: 35)!)
        label.numberOfLines = 1
        label.sizeToFit()
        return label
    }()
    
    private func createAttributedTitle(title: String, font: UIFont) -> NSMutableAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .kern: 1.50,
            .paragraphStyle: { () -> NSParagraphStyle in
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .natural
                return paragraphStyle
            }()
        ]
        let attributedButtonTitle = NSMutableAttributedString(string: title, attributes: attributes)
        return attributedButtonTitle
    }

    
    private lazy var momentumView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.3, alpha: 1)
        view.topColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value   // dark peach
        view.bottomColor = Colors.custom(hexString: "3f87ddff", alpha: 0.9).value // light peach
        view.cornerRadius = 30
        return view
    }()
    
    private lazy var handleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 1, alpha: 0.5)
        view.layer.cornerRadius = 3
        return view
    }()
    
    
    // todo: add an explicit tap recognizer as well
    private let panRecognizer = InstantPanGestureRecognizer()
    
    private var animator = UIViewPropertyAnimator()
    
    // todo: refactor state to use an enum with associated valued
    private var isOpen = false
    private var animationProgress: CGFloat = 0
    
    private var closedTransform = CGAffineTransform.identity
    
    
    
    var masterPath: [Vertex] = []
    var geodesicPolyline: MKGeodesicPolyline!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.addSubview(splashView)
//        return
        
        

        mapView.frame = view.frame
        mapView.delegate = self
        view.addSubview(mapView)
        
        showAnimatedDroneMessage(text: "Welcome to Hover! Get started by tapping two points on the map!")
        
        locationGraph = Graphs.World.graph
        mapView.addAnnotations(from: locationGraph)
        mapView.addEdges(from: locationGraph)
        
    
        panRecognizer.delegate = self
        button.tapRecognizer.delegate = self
        northAmericaButton.tapRecognizer.delegate = self
        northAmericaButton.onTap = {
            print("n Americ pressed!")
        }
        
        georgiaTechButton.tapRecognizer.delegate = self
        georgiaTechButton.onTap = {
            print("GT pressed!")
        }
        
        globalButton.tapRecognizer.delegate = self
        globalButton.onTap = {
            print("Global pressed!")
        }
        
        view.addSubview(momentumView)
        momentumView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4).isActive = true
        momentumView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4).isActive = true
        momentumView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 80).isActive = true
        momentumView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 140).isActive = true
        
        
        momentumView.addSubview(handleView)
        handleView.topAnchor.constraint(equalTo: momentumView.topAnchor, constant: 10).isActive = true
        handleView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        handleView.heightAnchor.constraint(equalToConstant: 5).isActive = true
        handleView.centerXAnchor.constraint(equalTo: momentumView.centerXAnchor).isActive = true
        
        closedTransform = CGAffineTransform(translationX: 0, y: view.bounds.height * 0.6)
        momentumView.transform = closedTransform
        
        panRecognizer.addTarget(self, action: #selector(panned))
        momentumView.addGestureRecognizer(panRecognizer)
        
        
        let startDot = Dot(color: Colors.custom(hexString: "#B2D080", alpha: 0.9).value)
        startDot.translatesAutoresizingMaskIntoConstraints = false
        momentumView.addSubview(startDot)
        startDot.translatesAutoresizingMaskIntoConstraints = false
        startDot.leadingAnchor.constraint(equalTo: momentumView.leadingAnchor, constant: 30).isActive = true
        startDot.topAnchor.constraint(equalTo: momentumView.topAnchor, constant: 150).isActive = true
        startDot.widthAnchor.constraint(equalToConstant: 20).isActive = true
        startDot.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        
        momentumView.addSubview(sourceLocationLabel)
        sourceLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        sourceLocationLabel.leadingAnchor.constraint(equalTo: startDot.trailingAnchor, constant: 10).isActive = true
        sourceLocationLabel.centerYAnchor.constraint(equalTo: startDot.centerYAnchor).isActive = true
        
        let sourceInfoView = CardView()
        momentumView.addSubview(sourceInfoView)
        sourceInfoView.translatesAutoresizingMaskIntoConstraints = false
        sourceInfoView.topAnchor.constraint(equalTo: sourceLocationLabel.bottomAnchor, constant: 5).isActive = true
        sourceInfoView.leadingAnchor.constraint(equalTo: startDot.leadingAnchor).isActive = true
        sourceInfoView.trailingAnchor.constraint(equalTo: momentumView.trailingAnchor, constant: -30).isActive = true
        sourceInfoView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        
        let endDot = Dot(color: Colors.custom(hexString: "#ff6348", alpha: 0.9).value)
        momentumView.addSubview(endDot)
        endDot.translatesAutoresizingMaskIntoConstraints = false
        endDot.leadingAnchor.constraint(equalTo: momentumView.leadingAnchor, constant: 30).isActive = true
        endDot.topAnchor.constraint(equalTo: sourceInfoView.bottomAnchor, constant: 75).isActive = true
        endDot.widthAnchor.constraint(equalToConstant: 20).isActive = true
        endDot.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        
        momentumView.addSubview(destinationLocationLabel)
        destinationLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        destinationLocationLabel.leadingAnchor.constraint(equalTo: endDot.trailingAnchor, constant: 10).isActive = true
        destinationLocationLabel.centerYAnchor.constraint(equalTo: endDot.centerYAnchor).isActive = true
        
        let destinationInfoView = CardView()
        momentumView.addSubview(destinationInfoView)
        destinationInfoView.translatesAutoresizingMaskIntoConstraints = false
        destinationInfoView.topAnchor.constraint(equalTo: destinationLocationLabel.bottomAnchor, constant: 5).isActive = true
        destinationInfoView.leadingAnchor.constraint(equalTo: endDot.leadingAnchor).isActive = true
        destinationInfoView.trailingAnchor.constraint(equalTo: momentumView.trailingAnchor, constant: -30).isActive = true
        destinationInfoView.heightAnchor.constraint(equalToConstant: 75).isActive = true
    
        momentumView.addSubview(graphTypeLabel)
        graphTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        graphTypeLabel.centerXAnchor.constraint(equalTo: momentumView.centerXAnchor).isActive = true

        

        globalButton.primaryTitle = "Global"
        globalButton.secondaryTitle = "Global"
        globalButton.titleFont = UIFont(name: "Rationale-Regular", size: 14)!
        globalButton.highlightedColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        globalButton.unselectedColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        momentumView.addSubview(globalButton)
        globalButton.translatesAutoresizingMaskIntoConstraints = false
        globalButton.bottomAnchor.constraint(equalTo: momentumView.bottomAnchor, constant: -140).isActive = true
        globalButton.centerXAnchor.constraint(equalTo: momentumView.centerXAnchor).isActive = true
        globalButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        
        georgiaTechButton.primaryTitle = "Georgia Tech"
        georgiaTechButton.secondaryTitle = "Tech"
        georgiaTechButton.titleFont = UIFont(name: "Rationale-Regular", size: 14)!
        georgiaTechButton.highlightedColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        georgiaTechButton.unselectedColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        momentumView.addSubview(georgiaTechButton)
        georgiaTechButton.translatesAutoresizingMaskIntoConstraints = false
        georgiaTechButton.bottomAnchor.constraint(equalTo: momentumView.bottomAnchor, constant: -140).isActive = true
        georgiaTechButton.leadingAnchor.constraint(equalTo: globalButton.trailingAnchor, constant: 10).isActive = true
        georgiaTechButton.trailingAnchor.constraint(equalTo: momentumView.trailingAnchor, constant: -12).isActive = true
        georgiaTechButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        

        northAmericaButton.primaryTitle =  "N. America"
        northAmericaButton.secondaryTitle =  "N. America"
        northAmericaButton.titleFont = UIFont(name: "Rationale-Regular", size: 14)!
        northAmericaButton.highlightedColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        northAmericaButton.unselectedColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        momentumView.addSubview(northAmericaButton)
        northAmericaButton.translatesAutoresizingMaskIntoConstraints = false
        northAmericaButton.bottomAnchor.constraint(equalTo: momentumView.bottomAnchor, constant: -140).isActive = true
        northAmericaButton.trailingAnchor.constraint(equalTo: globalButton.leadingAnchor, constant: -10).isActive = true
        northAmericaButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        northAmericaButton.leadingAnchor.constraint(equalTo: momentumView.leadingAnchor, constant: 12).isActive = true

        graphTypeLabel.bottomAnchor.constraint(equalTo: globalButton.topAnchor, constant: -15).isActive = true
        
        

        
        
        
        button.primaryTitle = "Find Shortest Path"
        button.secondaryTitle = "Reset"
        button.titleFont = UIFont(name: "Rationale-Regular", size: 22)!
        button.highlightedColor = Colors.custom(hexString: "#dff9fb", alpha: 0.9).value
        button.unselectedColor = Colors.custom(hexString: "#c7ecee", alpha: 0.9).value
        momentumView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 20).isActive = true
        button.centerXAnchor.constraint(equalTo: momentumView.centerXAnchor).isActive = true
        button.heightAnchor.constraint(equalToConstant: 65).isActive = true
       
        
        
        

        globalButton.isUserInteractionEnabled = true
        georgiaTechButton.isUserInteractionEnabled = true
        northAmericaButton.isUserInteractionEnabled = true
        
        
        
        
        
        
        
        button.onTap = {
            if self.button.label.attributedText?.string == "Find Shortest Path" {
                
                // we need to reset
                self.startVertex = nil
                self.goalVertex = nil
                //self.mapView.reloadInputViews()
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotations(from: self.locationGraph)
                
                self.mapView.removeOverlay(self.geodesicPolyline)
                
                self.mapView.annotations.forEach { anno in
                    self.mapView.deselectAnnotation(anno, animated: true)
                }
                
                
                self.mapView.removeAnnotation(self.planeAnnotation)
                self.flightpathPolyline = MKGeodesicPolyline()
                self.planeAnnotation = MKPointAnnotation()
                self.planeAnnotationPosition = 0
                
                self.masterPath = []
                print(self.masterPath)
                print("Map Cleaned")
                
                
            } else {
                print(self.startVertex!.key)
                print(self.goalVertex!.key)
                guard let path = self.locationGraph.performAStarSearch(from: self.startVertex!, to: self.goalVertex!) else { return }
                self.masterPath = path
                let locations = self.masterPath.map( { $0.coordinates } )
                self.geodesicPolyline = MKGeodesicPolyline(coordinates: locations, count: locations.count)
                self.geodesicPolyline.title = "PATH"
                self.mapView.addOverlay(self.geodesicPolyline)
                
                self.flightpathPolyline = MKGeodesicPolyline(coordinates: locations, count: locations.count)
                
                let planeAnnotation = MKPointAnnotation()
                planeAnnotation.title = "Drone"
                
                self.mapView.addAnnotation(planeAnnotation)
                
                self.planeAnnotation = planeAnnotation
                self.updatePlanePosition()
                
                print("done", self.masterPath)
            }

        }
        
    }
    
    @objc func updatePlanePosition() {
        let step = 200

        guard planeAnnotationPosition + step < self.flightpathPolyline.pointCount else { return }

        let points = flightpathPolyline.points()
        self.planeAnnotationPosition += step
        let nextMapPoint = points[planeAnnotationPosition]
        
        self.planeAnnotation.coordinate = nextMapPoint.coordinate
        
        perform(#selector(updatePlanePosition), with: nil, afterDelay: 0.3)
    }

}

extension ViewController {
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}


extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard view.annotation != nil else { return }
        
        handleAnnotationStateAndStyle(view, mapView)
    }

    
    internal func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        if annotation.title == "Drone" {
            let planeIdentifier = "Plane"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: planeIdentifier)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: planeIdentifier)
            annotationView.image = UIImage(named: "drone")
            return annotationView
        }
        
        if annotation is VertexPointAnnotation {
            
            let vertexPointAnnotation = annotation as! VertexPointAnnotation
            let circleAnnotationView = self.circleAnnotationView(in: mapView, for: vertexPointAnnotation)
            return circleAnnotationView
            
        }
        
        fatalError("Did an anotation type slip through?")
    }
    
    
    private func circleAnnotationView(in mapView: MKMapView, for annotation: MKAnnotation) -> CircleAnnotation {
        let identifier = "circleAnnotationViewID"
        print(annotation is VertexPointAnnotation)
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CircleAnnotation {
            annotationView.annotation = annotation
            return annotationView
        } else {
            let circleAnnotationView = CircleAnnotation(annotation: annotation, reuseIdentifier: identifier)
            return circleAnnotationView
        }
    }
    
    internal func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let testlineRenderer = MKPolylineRenderer(polyline: polyline)

            if polyline.title == Optional("PATH") {
                testlineRenderer.strokeColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
                testlineRenderer.lineWidth = 1.5
            } else {
                testlineRenderer.strokeColor = Colors.custom(hexString: "#ced6e0", alpha: 0.9).value
                testlineRenderer.lineWidth = 1.0
            }
            
            
            return testlineRenderer
        }
        fatalError("issue occured in rendererFor...")
    }
}

protocol CoordinateComputation {
    func addLocationVertex(name: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Vertex
}

protocol AStarSearchable {
    func computeHeuristicForVerticesRelativeTo(goalVertex: Vertex)
    func performAStarSearch(from start: Vertex, to goal: Vertex) -> [Vertex]?
}

extension Graph: CoordinateComputation {
    func addLocationVertex(name: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Vertex {
        let locationVertex: Vertex = Vertex(name: name, latitude: latitude, longitude: longitude)
        canvas.append(locationVertex)
        return locationVertex
    }
}

extension Graph: AStarSearchable {
    func computeHeuristicForVerticesRelativeTo(goalVertex: Vertex) {
        self.canvas.forEach { vertex in
            vertex.setHeuristicRelative(to: goalVertex)
        }
    }
    
    func performAStarSearch(from start: Vertex, to goal: Vertex) -> [Vertex]? {
        self.computeHeuristicForVerticesRelativeTo(goalVertex: goal)
        
        var path: [Vertex]?
        do {
            path = try self.aStarSearch(from: start, to: goal)
        } catch GraphError.emptyGraph {
            print(GraphError.emptyGraph.errorDescription!)
        } catch GraphError.startVertexNotInGraph {
            print(GraphError.startVertexNotInGraph.errorDescription!)
        } catch GraphError.goalVertexNotInGraph {
            print(GraphError.goalVertexNotInGraph.errorDescription!)
        } catch {
            print(error)
        }
        
        return path
    }
}

extension CLLocationCoordinate2D {
    
    func distance(from: CLLocationCoordinate2D) -> Int {
        let destination = CLLocation(latitude: from.latitude, longitude: from.longitude)
        return Int(CLLocation(latitude: self.latitude, longitude: self.longitude).distance(from: destination))
    }
    
}

class CircleAnnotation: MKAnnotationView {
    public static let annotationFrame: CGRect = CGRect(x: 0, y: 0, width: 10, height: 10)
    
    enum SelectedState {
        case unselected
        case start
        case goal
    }
    
    var state: SelectedState = .unselected
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        print("we killin it", annotation is VertexPointAnnotation)
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = CircleAnnotation.annotationFrame
        self.backgroundColor = .clear
        
        let circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(ovalIn: CircleAnnotation.annotationFrame).cgPath
        circleLayer.fillColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value.cgColor
        self.layer.addSublayer(circleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented!")
    }
    
    public func shrink(the view: MKAnnotationView) {
        self.layer.sublayers?.forEach {
            layer in
            if layer is CAShapeLayer {
                let gotem = layer as! CAShapeLayer
                
                UIView.animate(withDuration: 0.1) {
                    gotem.fillColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value.cgColor
                    view.transform = CGAffineTransform.identity
                }
            }
        }
    }
    
    public func expand(the view: MKAnnotationView, with cgcolor: CGColor) {
        self.layer.sublayers?.forEach {
            layer in
            if layer is CAShapeLayer {
                let gotem = layer as! CAShapeLayer
                
                UIView.animate(withDuration: 0.1) {
                    gotem.fillColor = cgcolor
                    view.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                }
            }
        }
    }

    
}


class VertexPointAnnotation: MKPointAnnotation {
    weak var associatedVertex: Vertex?
}

extension MKMapView {
    
    public func addAnnotations(from graph: Graph) {
        guard graph.canvas.isNotEmpty() else { return }
        graph.canvas.forEach { (vertex) in
            let annotation = VertexPointAnnotation()
            annotation.title = vertex.key
            annotation.coordinate = vertex.coordinates
            annotation.associatedVertex = vertex
            self.addAnnotation(annotation)
        }
    }
    
    public func addEdges(from graph: Graph) {
        guard graph.canvas.isNotEmpty() else { return }
        graph.canvas.forEach { (vertex) in
            var vertexAndNeighborCoordinates: [CLLocationCoordinate2D] = [vertex.coordinates]
            vertex.edges.forEach { (edge) in
                let neighbor = edge.anchor
                vertexAndNeighborCoordinates.append(neighbor.coordinates)
                
                let edgesPolylines = MKGeodesicPolyline(coordinates: vertexAndNeighborCoordinates, count: vertexAndNeighborCoordinates.count)
                
                self.addOverlay(edgesPolylines)
                vertexAndNeighborCoordinates.removeLast(1)
            }
        }
    }
    
}

extension ViewController {
    
    private func handleAnnotationStateAndStyle(_ view: MKAnnotationView, _ mapView: MKMapView) {
        if view is CircleAnnotation {
            
            let circleAnnotation = view as! CircleAnnotation
            
            // 🤯 allows for user to tap annotation again w/o having to tap somewhere else between
            mapView.deselectAnnotation(circleAnnotation.annotation, animated: false)
            
            /// Logic
            var containsStart: Bool = false
            var containsGoal: Bool = false
            
            for annotation in mapView.annotations {
                if let annotationView = mapView.view(for: annotation) {
                    if annotationView is CircleAnnotation {
                        let forcedCircleAnnotation = annotationView as! CircleAnnotation
                        if forcedCircleAnnotation.state == .start { containsStart = true }
                        if forcedCircleAnnotation.state == .goal { containsGoal = true }
                    }
                }
            }
            
            var newState: CircleAnnotation.SelectedState = .unselected // as an intial value ¯\_(ツ)_/¯
    
            let vertexAnnotation = circleAnnotation.annotation as! VertexPointAnnotation
            
            if !containsStart && !containsGoal {
                newState = .start
                circleAnnotation.expand(the: view, with: Colors.custom(hexString: "#B2D080", alpha: 0.9).value.cgColor)

                startVertex =  vertexAnnotation.associatedVertex

            } else if containsStart && containsGoal {
                newState = .unselected
                circleAnnotation.shrink(the: view)
                
                if circleAnnotation.state == .start {
                    // ✳️
                    startVertex = nil
                    
                } else if circleAnnotation.state == .goal {
                    // 🛑
                    goalVertex = nil
                }
                
            } else if containsStart {
                if circleAnnotation.state == .start {
                    newState = .unselected
                    circleAnnotation.shrink(the: view)
                    // ✳️
                    startVertex = nil
                    
                } else {
                    newState = .goal
                    circleAnnotation.expand(the: view, with: Colors.custom(hexString: "#ff6348", alpha: 0.9).value.cgColor)
                    // 🛑
                    goalVertex = vertexAnnotation.associatedVertex
                    
                }
                
            } else if containsGoal {
                if circleAnnotation.state == .goal {
                    newState = .unselected
                    circleAnnotation.shrink(the: view)
                    goalVertex = nil
                    
                } else {
                    newState = .start
                    circleAnnotation.expand(the: view, with: Colors.custom(hexString: "#B2D080", alpha: 0.9).value.cgColor)
                    startVertex = vertexAnnotation.associatedVertex
                }
            }
            
            // FINALLY SET STATE AND DABBBBBB
            circleAnnotation.state = newState
            
        }
    }
    
    
}




class BubbleView: UIView {
    
    var isIncoming = true
    
    var incomingColor = Colors.custom(hexString: "#3f87dd", alpha: 0.95).value//UIColor(white: 0.9, alpha: 1)
    var outgoingColor = Colors.custom(hexString: "#3f87dd", alpha: 0.95).value//UIColor(red: 0.09, green: 0.54, blue: 1, alpha: 1)
    
    override func draw(_ rect: CGRect) {
        let width = rect.width
        let height = rect.height
        
        let bezierPath = UIBezierPath()
        
        if isIncoming {
            bezierPath.move(to: CGPoint(x: 22, y: height))
            bezierPath.addLine(to: CGPoint(x: width - 17, y: height))
            bezierPath.addCurve(to: CGPoint(x: width, y: height - 17), controlPoint1: CGPoint(x: width - 7.61, y: height), controlPoint2: CGPoint(x: width, y: height - 7.61))
            bezierPath.addLine(to: CGPoint(x: width, y: 17))
            bezierPath.addCurve(to: CGPoint(x: width - 17, y: 0), controlPoint1: CGPoint(x: width, y: 7.61), controlPoint2: CGPoint(x: width - 7.61, y: 0))
            bezierPath.addLine(to: CGPoint(x: 21, y: 0))
            bezierPath.addCurve(to: CGPoint(x: 4, y: 17), controlPoint1: CGPoint(x: 11.61, y: 0), controlPoint2: CGPoint(x: 4, y: 7.61))
            bezierPath.addLine(to: CGPoint(x: 4, y: height - 11))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: 4, y: height - 1), controlPoint2: CGPoint(x: 0, y: height))
            bezierPath.addLine(to: CGPoint(x: -0.05, y: height - 0.01))
            bezierPath.addCurve(to: CGPoint(x: 11.04, y: height - 4.04), controlPoint1: CGPoint(x: 4.07, y: height + 0.43), controlPoint2: CGPoint(x: 8.16, y: height - 1.06))
            bezierPath.addCurve(to: CGPoint(x: 22, y: height), controlPoint1: CGPoint(x: 16, y: height), controlPoint2: CGPoint(x: 19, y: height))
            
            incomingColor.setFill()
            
        } else {
            bezierPath.move(to: CGPoint(x: width - 22, y: height))
            bezierPath.addLine(to: CGPoint(x: 17, y: height))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height - 17), controlPoint1: CGPoint(x: 7.61, y: height), controlPoint2: CGPoint(x: 0, y: height - 7.61))
            bezierPath.addLine(to: CGPoint(x: 0, y: 17))
            bezierPath.addCurve(to: CGPoint(x: 17, y: 0), controlPoint1: CGPoint(x: 0, y: 7.61), controlPoint2: CGPoint(x: 7.61, y: 0))
            bezierPath.addLine(to: CGPoint(x: width - 21, y: 0))
            bezierPath.addCurve(to: CGPoint(x: width - 4, y: 17), controlPoint1: CGPoint(x: width - 11.61, y: 0), controlPoint2: CGPoint(x: width - 4, y: 7.61))
            bezierPath.addLine(to: CGPoint(x: width - 4, y: height - 11))
            bezierPath.addCurve(to: CGPoint(x: width, y: height), controlPoint1: CGPoint(x: width - 4, y: height - 1), controlPoint2: CGPoint(x: width, y: height))
            bezierPath.addLine(to: CGPoint(x: width + 0.05, y: height - 0.01))
            bezierPath.addCurve(to: CGPoint(x: width - 11.04, y: height - 4.04), controlPoint1: CGPoint(x: width - 4.07, y: height + 0.43), controlPoint2: CGPoint(x: width - 8.16, y: height - 1.06))
            bezierPath.addCurve(to: CGPoint(x: width - 22, y: height), controlPoint1: CGPoint(x: width - 16, y: height), controlPoint2: CGPoint(x: width - 19, y: height))
            
            outgoingColor.setFill()
        }
        
        bezierPath.close()
        bezierPath.fill()
    }
    
}

extension ViewController {
    
    func showAnimatedDroneMessage(text: String) {
        let label =  UILabel()
        label.numberOfLines = 0
        label.font = UIFont(name: "Rationale-Regular", size: 16)!
        label.textColor = .white
        label.text = text
        
        let constraintRect = CGSize(width: 0.66 * view.frame.width,
                                    height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: label.font!],
                                            context: nil)
        label.frame.size = CGSize(width: ceil(boundingBox.width),
                                  height: ceil(boundingBox.height))
        
        let bubbleSize = CGSize(width: label.frame.width + 23,
                                height: label.frame.height + 15)
        let bubbleView = BubbleView(frame: CGRect(x: -bubbleSize.width, y: 200, width: bubbleSize.width, height: bubbleSize.height))
        
        bubbleView.backgroundColor = .clear
        view.addSubview(bubbleView)
        
        label.center = bubbleView.center
        view.addSubview(label)
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.curveEaseInOut], animations: {
            bubbleView.frame.origin.x += bubbleSize.width + 100
            label.frame.origin.x += bubbleSize.width + 100
        }) { (_) in
            UIView.animate(withDuration: 1.0, delay: 3.0, options: [.curveEaseIn], animations: {
                bubbleView.frame.origin.x -= bubbleSize.width + 100
                label.frame.origin.x -= bubbleSize.width + 100
            }, completion: nil)
        }
        
        
        let containerView = UIView(frame: CGRect(x: -100 - bubbleSize.width, y: 180, width: 100, height: 100))
        view.addSubview(containerView)
        
        let rotatingImageView = UIImageView(frame: containerView.bounds)
        rotatingImageView.image = UIImage(named: "drone")?.withRenderingMode(.alwaysOriginal)
        containerView.addSubview(rotatingImageView)
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.curveEaseInOut], animations: {
            containerView.frame.origin.x += bubbleSize.width + 100
            rotatingImageView.transform = CGAffineTransform(rotationAngle: .pi / 16)
        }) { (_) in
            UIView.animate(withDuration: 1.0, delay: 3.0, options: [.curveEaseIn], animations: {
                containerView.frame.origin.x -= bubbleSize.width + 100
                rotatingImageView.transform = .identity
            }, completion: nil)
        }
    }
    
}


class Dot: UIView {
    var color: UIColor = UIColor.black
    
    init(_ frame: CGRect = CGRect.zero, color: UIColor) {
        super.init(frame: frame)
        self.color = color
    }
    
    lazy var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        layer.fillColor = self.color.cgColor
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !frame.isEmpty { self.layer.addSublayer(circleLayer) }
        
    }
    
    
}



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
