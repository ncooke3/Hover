//
//  ViewController.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 8/30/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    lazy var splashView = SplashView(frame: self.view.frame)

    var mapView = MKMapView()
    var locationGraph: Graph!
    
    var flightpathPolyline = MKGeodesicPolyline()
    var planeAnnotation: MKPointAnnotation!
    var planeAnnotationPosition = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //view.addSubview(splashView)
        
        //return
            
        mapView.frame = view.frame
        mapView.delegate = self
        view.addSubview(mapView)

    
        locationGraph = Graphs.NorthAmerica.graph
        mapView.addAnnotations(from: locationGraph)
        mapView.addEdges(from: locationGraph)
        
        guard let path = locationGraph.performAStarSearch(from: LosAngeles, to: Miami) else { return }
        
        let locations = path.map( { $0.coordinates } )
        let geodesicPolyline = MKGeodesicPolyline(coordinates: locations, count: locations.count)
        geodesicPolyline.title = "PATH"
        mapView.addOverlay(geodesicPolyline)
        
        self.flightpathPolyline = MKGeodesicPolyline(coordinates: locations, count: locations.count)

        let planeAnnotation = MKPointAnnotation()
        
        planeAnnotation.title = "Drone"
        
        mapView.addAnnotation(planeAnnotation)
        
        self.planeAnnotation = planeAnnotation
        self.updatePlanePosition()
        
    }
    
    @objc func updatePlanePosition() {
        let step = 100

        guard planeAnnotationPosition + step < self.flightpathPolyline.pointCount else { return }

        let points = flightpathPolyline.points()
        self.planeAnnotationPosition += step
        let nextMapPoint = points[planeAnnotationPosition]
        
        self.planeAnnotation.coordinate = nextMapPoint.coordinate
        
        perform(#selector(updatePlanePosition), with: nil, afterDelay: 0.3)
    }

}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard view.annotation != nil else { return }
        
        if view is CircleAnnotation {
            
            let circleAnnotation = view as! CircleAnnotation
            
            // 🤯 allows for user to tap annotation again w/o having to tap somewhere else between
            mapView.deselectAnnotation(circleAnnotation.annotation, animated: false)
            
            
            /// Logic
            var containsStart: Bool = false
            var containsGoal: Bool = false
            
            for annotation in mapView.annotations {
                //guard let annotationView = mapView.view(for: annotation) else { print("here"); return }
                //guard annotationView is CircleAnnotation else { print("there"); return }
                if let annotationView = mapView.view(for: annotation) {
                    if annotationView is CircleAnnotation {
                        let forcedCircleAnnotation = annotationView as! CircleAnnotation
                        if forcedCircleAnnotation.state == .start { containsStart = true }
                        if forcedCircleAnnotation.state == .goal { containsGoal = true }
                    }
                }
            }

            
            // atp, containsStart & containsGoal are set
            
            var newState: CircleAnnotation.SelectedState = .unselected // as an intial value ¯\_(ツ)_/¯
            
            /// Both do not exist
            if !containsStart && !containsGoal {
                // set tapped to S
                newState = .start
                
                // ENLARGE S
                //ENLARGE S
                circleAnnotation.layer.sublayers?.forEach {
                    layer in
                    if layer is CAShapeLayer {
                        let gotem = layer as! CAShapeLayer
                        print("hello")
                        DispatchQueue.main.async {
                            UIView.animate(withDuration: 0.3) {
                                gotem.fillColor = UIColor.green.withAlphaComponent(0.9).cgColor
                                view.transform = CGAffineTransform(scaleX: 1.75, y: 1.75)
                            }
                        }

                    }
                }
                

                
            } else
            
            /// Both exist
            if containsStart && containsGoal {
                // if S was tapped -> set IT to U
                // if G was tapped -> set IT to U
                // if U was tapped -> do nothing!
                
                // ternary: tapped.state = U
                newState = .unselected
                
                //if circleAnnotation.state == .start || circleAnnotation.state == .goal {
                    
                    
                    /// SHRINK S / G
                    circleAnnotation.layer.sublayers?.forEach {
                        layer in
                        if layer is CAShapeLayer {
                            let gotem = layer as! CAShapeLayer
                            
                            UIView.animate(withDuration: 0.3) {
                                gotem.fillColor = Colors.orange.withAlpha(0.9).cgColor
                                view.transform = CGAffineTransform.identity
                            }
                            
                            
                        }
                    }
                    


            } else
            
            // atp, either Start or Goal exists
            if containsStart {
                // if S was tapped -> set IT to U
                // ELSE -> set IT to G!!!!!
                
                // ternary: tapped.state = tapped.state == S ? U : G
                //newState = circleAnnotation.state == .start ? .unselected : .goal
                
                if circleAnnotation.state == .start {
                    newState = .unselected
                    
                    // SHRINK S
                    /// SHRINK S / G
                    circleAnnotation.layer.sublayers?.forEach {
                        layer in
                        if layer is CAShapeLayer {
                            let gotem = layer as! CAShapeLayer
                            
                            UIView.animate(withDuration: 0.3) {
                                gotem.fillColor = Colors.orange.withAlpha(0.9).cgColor
                                view.transform = CGAffineTransform.identity
                            }
                            
                            
                        }
                    }
                    
                    
                } else {
                    newState = .goal
                    
                    // ENLARGE G
                    /// ENLARGE G
                    circleAnnotation.layer.sublayers?.forEach {
                        layer in
                        if layer is CAShapeLayer {
                            let gotem = layer as! CAShapeLayer
                            
                            UIView.animate(withDuration: 0.3) {
                                gotem.fillColor = Colors.red.withAlpha(0.9).cgColor
                                view.transform = CGAffineTransform(scaleX: 1.75, y: 1.75)
                            }
                            
                            
                        }
                    }
                }
                
   
                
            } else
            
            if containsGoal {
                // if G was tapped -> set IT to U
                // ELSE -> set IT to G
                
                // ternary: tapped.state = tapped.state == G ? U : S
                //newState = circleAnnotation.state == .goal ? .unselected : .start
                
                if circleAnnotation.state == .goal {
                    newState = .unselected
                    
                    //SHRINK G
                    /// SHRINK S / G
                    circleAnnotation.layer.sublayers?.forEach {
                        layer in
                        if layer is CAShapeLayer {
                            let gotem = layer as! CAShapeLayer
                            
                            UIView.animate(withDuration: 0.3) {
                                gotem.fillColor = Colors.orange.withAlpha(0.9).cgColor
                                view.transform = CGAffineTransform.identity
                            }
                            
                            
                        }
                    }
                    
 
                } else {
                    newState = .start
                    
                    //ENLARGE S
                    circleAnnotation.layer.sublayers?.forEach {
                        layer in
                        if layer is CAShapeLayer {
                            let gotem = layer as! CAShapeLayer
                            
                            UIView.animate(withDuration: 0.3) {
                                gotem.fillColor = UIColor.green.withAlphaComponent(0.9).cgColor
                                view.transform = CGAffineTransform(scaleX: 1.75, y: 1.75)
                            }
                        }
                    }
                    
                    
                }
            }
            

            
            
            // FINALLY SET STATE AND DABBBBBB
            circleAnnotation.state = newState

                
            }
    }


    
    internal func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        if annotation.title == "Drone" {
            let planeIdentifier = "Plane"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: planeIdentifier)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: planeIdentifier)
            
            annotationView.image = UIImage(named: "drone-2")
            return annotationView
        }
        let circleAnnotationView = self.circleAnnotationView(in: mapView, for: annotation)
        return circleAnnotationView
    }
    
    
    private func circleAnnotationView(in mapView: MKMapView, for annotation: MKAnnotation) -> CircleAnnotation {
        let identifier = "circleAnnotationViewID"
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CircleAnnotation {
            annotationView.annotation = annotation
            return annotationView
        } else {
            let circleAnnotationView = CircleAnnotation(annotation: annotation, reuseIdentifier: identifier)
            circleAnnotationView.canShowCallout = true
            return circleAnnotationView
        }
    }
    
    internal func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let testlineRenderer = MKPolylineRenderer(polyline: polyline)

            if polyline.title == Optional("PATH") {
                testlineRenderer.strokeColor = Colors.lightOrange.value
                testlineRenderer.lineWidth = 1.5
            } else {
                testlineRenderer.strokeColor = UIColor.lightGray.withAlphaComponent(0.6)
                testlineRenderer.lineWidth = 1.0
            }
            
            
            return testlineRenderer
        }
        fatalError("Something wrong...")
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
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = CircleAnnotation.annotationFrame
        self.backgroundColor = .clear
        
        let circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(ovalIn: CircleAnnotation.annotationFrame).cgPath
        circleLayer.fillColor = Colors.orange.withAlpha(0.9).cgColor
        self.layer.addSublayer(circleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented!")
    }
}

extension MKMapView {
    
    public func addAnnotations(from graph: Graph) {
        guard graph.canvas.isNotEmpty() else { return }
        graph.canvas.forEach { (vertex) in
            let annotation = MKPointAnnotation()
            annotation.title = vertex.key
            annotation.coordinate = vertex.coordinates
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
