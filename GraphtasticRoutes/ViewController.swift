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

    var mapView = MKMapView()
    var locationGraph: Graph!
    
    var flightpathPolyline = MKGeodesicPolyline()
    var planeAnnotation: MKPointAnnotation!
    var planeAnnotationPosition = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.frame = view.frame
        mapView.delegate = self
        view.addSubview(mapView)
        
        locationGraph = Graphs.World.graph
        mapView.addAnnotations(from: locationGraph)
        mapView.addEdges(from: locationGraph)
        
        guard let path = locationGraph.performAStarSearch(from: NewYork, to: Perth) else { return }
        
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
    private let annotationFrame: CGRect = CGRect(x: 0, y: 0, width: 10, height: 10)
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = annotationFrame
        self.backgroundColor = .clear
        
        let circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(ovalIn: annotationFrame).cgPath
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
