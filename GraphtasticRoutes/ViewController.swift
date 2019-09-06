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

class ViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    lazy var splashView = SplashView(frame: self.view.frame)

    var mapView = MKMapView()
    var locationGraph: Graph!
    
    var northAmericaButton = UIButton()
    var globalButton = UIButton()
    var georgiaTechButton = UIButton()
    
    var button: CustomButton = {
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
        label.attributedText = createAttributedTitle(title: "Start", font: UIFont(name: "Rationale-Regular", size: 35)!)
        label.numberOfLines = 1
        label.sizeToFit()
        return label
    }()
    
    lazy var destinationLocationLabel: UILabel = {
        let label = UILabel()
        label.attributedText = createAttributedTitle(title: "End", font: UIFont(name: "Rationale-Regular", size: 35)!)
        label.numberOfLines = 1
        label.sizeToFit()
        return label
    }()
    
    var shortestDistanceLabel = AnimatedLabel()

    private lazy var momentumView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.3, alpha: 1)
        view.topColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        view.bottomColor = Colors.custom(hexString: "3f87ddff", alpha: 0.9).value
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
    
    private let panRecognizer = InstantPanGestureRecognizer()
    private var animator = UIViewPropertyAnimator()
    private var isOpen = false
    private var animationProgress: CGFloat = 0
    private var closedTransform = CGAffineTransform.identity
    
    var flightpathPolyline = MKGeodesicPolyline()
    var planeAnnotation: MKPointAnnotation!
    var planeAnnotationPosition = 0
    
    var masterPath: [Vertex] = []
    var geodesicPolyline: MKGeodesicPolyline!
    var startVertexAnnotation: MKAnnotation?
    var goalVertexAnnotation: MKAnnotation?
    
    var canUserEditAnnotations: Bool = true
    
    var userInputToggle: Bool! {
        didSet {
            button.isUserInteractionEnabled = userInputToggle
            UIView.animate(withDuration: 0.2) {
                self.button.alpha = self.userInputToggle ? 1 : 0.6
            }
            
        }
    }
    
    var startVertex: Vertex? {
        didSet {
            userInputToggle = startVertex != nil && goalVertex != nil
            sourceLocationLabel.attributedText = createAttributedTitle(title: startVertex?.key ?? "Start", font: UIFont(name: "Rationale-Regular", size: 35)!)
        }
    }
    
    var goalVertex: Vertex? {
        didSet {
            userInputToggle = startVertex != nil && goalVertex != nil
            destinationLocationLabel.attributedText = createAttributedTitle(title: goalVertex?.key ?? "End", font: UIFont(name: "Rationale-Regular", size: 35)!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHoverView()
        
        view.addSubview(splashView)
        splashView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        splashView.alpha = 0
        
        UIView.animate(withDuration: 0.2) {
            self.splashView.alpha = 1
            self.splashView.transform = CGAffineTransform.identity
        }
        
        let welcomeViewTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(animateOutSplashview))
        welcomeViewTapRecognizer.numberOfTapsRequired = 1
        welcomeViewTapRecognizer.numberOfTouchesRequired = 1
        splashView.addGestureRecognizer(welcomeViewTapRecognizer)
        
    }
    
    @objc func animateOutSplashview() {
        
        UIView.animate(withDuration: 0.3, delay: 0, animations: {
            self.splashView.alpha = 0
            self.mapView.alpha = 1
        }) { (success: Bool) in
            self.splashView.removeFromSuperview()
            self.showAnimatedDroneMessage(text: "Welcome to Hover! Get started by tapping two points on the map!")
        }

    }
    
    @objc func northAmericaButtonTapped() {
        self.safelyClearsCurrentGraph()
        self.locationGraph.removeEdges()
        self.locationGraph = Graphs.NorthAmerica.graph
        self.setupGraph(with: self.locationGraph)
        mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.13, longitude: -95.7855), span: MKCoordinateSpan(latitudeDelta: 97.66728, longitudeDelta: 61.27601)), animated: true)
    }
    
    @objc func globalButtonTapped() {
        self.safelyClearsCurrentGraph()
        self.locationGraph.removeEdges()
        self.locationGraph = Graphs.World.graph
        self.setupGraph(with: self.locationGraph)
        mapView.setRegion(MKCoordinateRegion(MKMapRect.world), animated: true)
    }
    
    @objc func georgiaTechButtonTapped() {
        self.safelyClearsCurrentGraph()
        self.locationGraph.removeEdges()
        self.locationGraph = Graphs.GeorgiaTech.graph
        self.setupGraph(with: self.locationGraph)
        let region = MKCoordinateRegion(center: Clough.coordinates, latitudinalMeters: CLLocationDistance(exactly: 3500)!, longitudinalMeters: CLLocationDistance(exactly: 3500)!)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
        
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

    private func setupHoverView() {
        userInputToggle = false
        setupMapView()
        setupGraph(with: Graphs.World.graph)
        
        panRecognizer.delegate = self
        setupMomentumView()
        setupThinHandleView()
        closedTransform = CGAffineTransform(translationX: 0, y: view.bounds.height * 0.6)
        momentumView.transform = closedTransform
        panRecognizer.addTarget(self, action: #selector(panned))
        momentumView.addGestureRecognizer(panRecognizer)
        
        // Setup MomentumView subviews
        setupStartViews()
        setupDestinationViews()
        setupGraphTypeLabel()
        
        // Setup Buttons
        setupGlobalButton()
        setupNorthAmericaButton()
        setupGeorgiaTechButton()
        setupShortestPathButton()
        
        let distanceLabel = UILabel()
        distanceLabel.text = "Distance:"
        distanceLabel.font = UIFont(name: "Rationale-Regular", size: 25)!
        distanceLabel.textColor = .white
        distanceLabel.backgroundColor = .clear
        momentumView.addSubview(distanceLabel)
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.topAnchor.constraint(equalTo: destinationLocationLabel.bottomAnchor, constant: 5).isActive = true
        distanceLabel.leadingAnchor.constraint(equalTo: destinationLocationLabel.leadingAnchor).isActive = true
        
        shortestDistanceLabel.font = UIFont(name: "Rationale-Regular", size: 25)!
        shortestDistanceLabel.sizeToFit()
        shortestDistanceLabel.backgroundColor = .clear
        shortestDistanceLabel.textColor = .white
        momentumView.addSubview(shortestDistanceLabel)
        shortestDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        shortestDistanceLabel.topAnchor.constraint(equalTo: destinationLocationLabel.bottomAnchor, constant: 5).isActive = true
        shortestDistanceLabel.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: 10).isActive = true
        
        let unitsLabel = UILabel()
        unitsLabel.text = "miles"
        unitsLabel.font = UIFont(name: "Rationale-Regular", size: 25)!
        unitsLabel.textColor = .white
        unitsLabel.backgroundColor = .clear
        momentumView.addSubview(unitsLabel)
        unitsLabel.translatesAutoresizingMaskIntoConstraints = false
        unitsLabel.topAnchor.constraint(equalTo: destinationLocationLabel.bottomAnchor, constant: 5).isActive = true
        unitsLabel.leadingAnchor.constraint(equalTo: shortestDistanceLabel.trailingAnchor, constant: 5).isActive = true
        
        button.onTap = {
            if self.button.label.attributedText?.string == "Find Shortest Path" {
                let startVertexAnnotationView = self.mapView.view(for: self.startVertexAnnotation!) as! CircleAnnotation
                startVertexAnnotationView.state = .unselected
                startVertexAnnotationView.shrink(the: startVertexAnnotationView)
                
                let goalVertexAnnotationView = self.mapView.view(for: self.goalVertexAnnotation!) as! CircleAnnotation
                goalVertexAnnotationView.state = .unselected
                goalVertexAnnotationView.shrink(the: goalVertexAnnotationView)
                
                self.startVertex = nil
                self.goalVertex = nil
                
                self.mapView.removeOverlay(self.geodesicPolyline)
                self.mapView.removeAnnotation(self.planeAnnotation)
                self.flightpathPolyline = MKGeodesicPolyline()
                self.planeAnnotation = MKPointAnnotation()
                self.planeAnnotationPosition = 0
                self.masterPath = []
                self.canUserEditAnnotations = true
                self.shortestDistanceLabel.stop()
                self.shortestDistanceLabel.text = "0"
                
            } else {
                
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
                
                if locations.count > 1 {
                    var shortestDist: Int = 0
                    
                    for index in 0..<locations.count - 1 {
                        shortestDist += locations[index].distance(from: locations[index + 1])
                    }
                    
                    self.shortestDistanceLabel.countFromZero(to: Float(shortestDist) * 0.000621371 )
                }
                
                self.updatePlanePosition()
                self.canUserEditAnnotations = false
                
            }
            
        }
    }
    
    private func setupGlobalButton() {
        globalButton.setTitle("         Global         ", for: .normal)
        globalButton.titleLabel?.font = UIFont(name: "Rationale-Regular", size: 14)!
        globalButton.backgroundColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        globalButton.layer.cornerRadius = 18
        momentumView.addSubview(globalButton)
        globalButton.translatesAutoresizingMaskIntoConstraints = false
        globalButton.bottomAnchor.constraint(equalTo: momentumView.bottomAnchor, constant: -160).isActive = true
        globalButton.centerXAnchor.constraint(equalTo: momentumView.centerXAnchor).isActive = true
        globalButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        globalButton.addTarget(self, action: #selector(globalButtonTapped), for: .touchUpInside)
    }
    
    private func setupNorthAmericaButton() {
        northAmericaButton.setTitle("   North America   ", for: .normal)
        northAmericaButton.titleLabel?.font = UIFont(name: "Rationale-Regular", size: 14)!
        northAmericaButton.backgroundColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        northAmericaButton.layer.cornerRadius = 18
        momentumView.addSubview(northAmericaButton)
        northAmericaButton.translatesAutoresizingMaskIntoConstraints = false
        northAmericaButton.bottomAnchor.constraint(equalTo: momentumView.bottomAnchor, constant: -160).isActive = true
        northAmericaButton.centerYAnchor.constraint(equalTo: globalButton.centerYAnchor).isActive = true
        northAmericaButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        northAmericaButton.trailingAnchor.constraint(equalTo: globalButton.leadingAnchor, constant: -10).isActive = true
        northAmericaButton.addTarget(self, action: #selector(northAmericaButtonTapped), for: .touchUpInside)
        northAmericaButton.leadingAnchor.constraint(equalTo: momentumView.leadingAnchor, constant: 30).isActive = true
    }
    
    private func setupGeorgiaTechButton() {
        georgiaTechButton.setTitle("   Georgia Tech   ", for: .normal)
        georgiaTechButton.titleLabel?.font = UIFont(name: "Rationale-Regular", size: 14)!
        georgiaTechButton.backgroundColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        georgiaTechButton.layer.cornerRadius = 18
        momentumView.addSubview(georgiaTechButton)
        georgiaTechButton.translatesAutoresizingMaskIntoConstraints = false
        georgiaTechButton.bottomAnchor.constraint(equalTo: momentumView.bottomAnchor, constant: -160).isActive = true
        georgiaTechButton.leadingAnchor.constraint(equalTo: globalButton.trailingAnchor, constant: 10).isActive = true
        georgiaTechButton.trailingAnchor.constraint(equalTo: momentumView.trailingAnchor, constant: -30).isActive = true
        georgiaTechButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        georgiaTechButton.addTarget(self, action: #selector(georgiaTechButtonTapped), for: .touchUpInside)
    }
    
    private func setupMapView() {
        mapView.frame = view.frame
        mapView.delegate = self
        view.addSubview(mapView)
        mapView.alpha = 0
    }
    
    private func setupGraph(with graph: Graph) {
        locationGraph = graph
        mapView.addAnnotations(from: locationGraph)
        mapView.addEdges(from: locationGraph)
    }
    
    private func safelyClearsCurrentGraph() {
        self.startVertex = nil
        self.goalVertex = nil
        if self.geodesicPolyline != nil { self.mapView.removeOverlay(self.geodesicPolyline) }
        if self.planeAnnotation != nil { self.mapView.removeAnnotation(self.planeAnnotation) }
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.removeOverlays(self.mapView.overlays)
        self.flightpathPolyline = MKGeodesicPolyline()
        self.planeAnnotation = MKPointAnnotation()
        self.planeAnnotationPosition = 0
        self.masterPath = []
    }
    
    private func setupShortestPathButton() {
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
    }
    
    private func setupWorldButton() {
        globalButton.setTitle("Global", for: .normal)
        globalButton.titleLabel?.font = UIFont(name: "Rationale-Regular", size: 14)!
        globalButton.backgroundColor = Colors.custom(hexString: "#3f87dd", alpha: 0.9).value
        globalButton.layer.cornerRadius = 15
        momentumView.addSubview(globalButton)
        globalButton.translatesAutoresizingMaskIntoConstraints = false
        globalButton.bottomAnchor.constraint(equalTo: momentumView.bottomAnchor, constant: -160).isActive = true
        globalButton.centerXAnchor.constraint(equalTo: momentumView.centerXAnchor).isActive = true
        globalButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        globalButton.addTarget(self, action: #selector(globalButtonTapped), for: .touchUpInside)
    }
    
    private func setupStartViews() {
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
        
        let startZeroDistanceLabel = UILabel()
        startZeroDistanceLabel.text = "Distance:  0 miles"
        startZeroDistanceLabel.font = UIFont(name: "Rationale-Regular", size: 25)!
        startZeroDistanceLabel.textColor = .white
        startZeroDistanceLabel.backgroundColor = .clear
        momentumView.addSubview(startZeroDistanceLabel)
        startZeroDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        startZeroDistanceLabel.topAnchor.constraint(equalTo: sourceLocationLabel.bottomAnchor, constant: 5).isActive = true
        startZeroDistanceLabel.leadingAnchor.constraint(equalTo: sourceLocationLabel.leadingAnchor).isActive = true
        
    }
    
    private func setupGraphTypeLabel() {
        momentumView.addSubview(graphTypeLabel)
        graphTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        graphTypeLabel.centerXAnchor.constraint(equalTo: momentumView.centerXAnchor).isActive = true
        graphTypeLabel.topAnchor.constraint(equalTo: destinationLocationLabel.bottomAnchor, constant: 100).isActive = true
    }
    
    private func setupDestinationViews() {
        let endDot = Dot(color: Colors.custom(hexString: "#ff6348", alpha: 0.9).value)
        momentumView.addSubview(endDot)
        endDot.translatesAutoresizingMaskIntoConstraints = false
        endDot.leadingAnchor.constraint(equalTo: momentumView.leadingAnchor, constant: 30).isActive = true
        endDot.topAnchor.constraint(equalTo: sourceLocationLabel.bottomAnchor, constant: 130).isActive = true
        endDot.widthAnchor.constraint(equalToConstant: 20).isActive = true
        endDot.heightAnchor.constraint(equalToConstant: 20).isActive = true
        momentumView.addSubview(destinationLocationLabel)
        destinationLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        destinationLocationLabel.leadingAnchor.constraint(equalTo: endDot.trailingAnchor, constant: 10).isActive = true
        destinationLocationLabel.centerYAnchor.constraint(equalTo: endDot.centerYAnchor).isActive = true
        
    }
    
    private func setupMomentumView() {
        view.addSubview(momentumView)
        momentumView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4).isActive = true
        momentumView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4).isActive = true
        momentumView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 80).isActive = true
        momentumView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 140).isActive = true
    }
    
    private func setupThinHandleView() {
        momentumView.addSubview(handleView)
        handleView.topAnchor.constraint(equalTo: momentumView.topAnchor, constant: 10).isActive = true
        handleView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        handleView.heightAnchor.constraint(equalToConstant: 5).isActive = true
        handleView.centerXAnchor.constraint(equalTo: momentumView.centerXAnchor).isActive = true
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
        guard canUserEditAnnotations else { return }
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

extension ViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        let buttonContainsTouch = button.frame.contains(touch.location(in: momentumView))
        let americaButtonContainsTouch = northAmericaButton.frame.contains(touch.location(in: momentumView))
        let globalButtonContainsTouch = globalButton.frame.contains(touch.location(in: momentumView))
        let georgiaTechButtonContainsTouch = georgiaTechButton.frame.contains(touch.location(in: momentumView))
        
        if buttonContainsTouch || americaButtonContainsTouch || globalButtonContainsTouch || georgiaTechButtonContainsTouch {
            if gestureRecognizer == panRecognizer {
                return false
            }
        }
        return true
    }
    
}


extension ViewController {
    
    // This is pretty much a black box of logic 😂. Probably could have been more slick
    private func handleAnnotationStateAndStyle(_ view: MKAnnotationView, _ mapView: MKMapView) {
        if view is CircleAnnotation {
            
            let circleAnnotation = view as! CircleAnnotation
            
            // 🤯 allows for user to tap annotation again w/o having to tap somewhere else between
            mapView.deselectAnnotation(circleAnnotation.annotation, animated: false)
            
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
                startVertexAnnotation = circleAnnotation.annotation
                startVertex =  vertexAnnotation.associatedVertex

            } else if containsStart && containsGoal {
                newState = .unselected
                circleAnnotation.shrink(the: view)
                
                if circleAnnotation.state == .start {
                    // ✳️
                    startVertexAnnotation = nil
                    startVertex = nil
                    
                } else if circleAnnotation.state == .goal {
                    // 🛑
                    goalVertexAnnotation = nil
                    goalVertex = nil
                }
                
            } else if containsStart {
                if circleAnnotation.state == .start {
                    newState = .unselected
                    circleAnnotation.shrink(the: view)
                    // ✳️
                    startVertexAnnotation = nil
                    startVertex = nil
                    
                } else {
                    newState = .goal
                    circleAnnotation.expand(the: view, with: Colors.custom(hexString: "#ff6348", alpha: 0.9).value.cgColor)
                    // 🛑
                    goalVertexAnnotation = circleAnnotation.annotation
                    goalVertex = vertexAnnotation.associatedVertex
                    
                }
                
            } else if containsGoal {
                if circleAnnotation.state == .goal {
                    newState = .unselected
                    circleAnnotation.shrink(the: view)
                    goalVertexAnnotation = nil
                    goalVertex = nil
                    
                } else {
                    newState = .start
                    circleAnnotation.expand(the: view, with: Colors.custom(hexString: "#B2D080", alpha: 0.9).value.cgColor)
                    startVertexAnnotation = circleAnnotation.annotation
                    startVertex = vertexAnnotation.associatedVertex
                }
            }
            
            // FINALLY SET STATE AND DABBBBBB
            circleAnnotation.state = newState
        }
    }
    
    
}

extension ViewController {
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
        
        let bubbleView = BubbleView(frame: CGRect(x: -bubbleSize.width, y: 200,
                                                  width: bubbleSize.width,
                                                  height: bubbleSize.height))
        
        bubbleView.backgroundColor = .clear
        view.insertSubview(bubbleView, belowSubview: self.momentumView)
        
        label.center = bubbleView.center
        view.insertSubview(label, belowSubview: self.momentumView)
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.curveEaseInOut], animations: {
            bubbleView.frame.origin.x += bubbleSize.width + 100
            label.frame.origin.x += bubbleSize.width + 100
        }) { (_) in
            UIView.animate(withDuration: 1.0, delay: 5.0, options: [.curveEaseIn], animations: {
                bubbleView.frame.origin.x -= bubbleSize.width + 100
                label.frame.origin.x -= bubbleSize.width + 100
            }, completion: nil)
        }
        
        
        let containerView = UIView(frame: CGRect(x: -100 - bubbleSize.width, y: 180, width: 100, height: 100))
        view.insertSubview(containerView, belowSubview: self.momentumView)
        
        let rotatingImageView = UIImageView(frame: containerView.bounds)
        rotatingImageView.image = UIImage(named: "drone")?.withRenderingMode(.alwaysOriginal)
        containerView.addSubview(rotatingImageView)
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.curveEaseInOut], animations: {
            containerView.frame.origin.x += bubbleSize.width + 100
            rotatingImageView.transform = CGAffineTransform(rotationAngle: .pi / 16)
        }) { (_) in
            UIView.animate(withDuration: 1.0, delay: 5.0, options: [.curveEaseIn], animations: {
                containerView.frame.origin.x -= bubbleSize.width + 100
                rotatingImageView.transform = .identity
            }, completion: nil)
        }
    }
    
}

extension ViewController {
    
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

extension CLLocationCoordinate2D {
    
    func distance(from: CLLocationCoordinate2D) -> Int {
        let destination = CLLocation(latitude: from.latitude, longitude: from.longitude)
        return Int(CLLocation(latitude: self.latitude, longitude: self.longitude).distance(from: destination))
    }
    
}
