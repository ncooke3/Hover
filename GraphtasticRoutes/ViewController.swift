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
        
        
        
        locationGraph = Graph()
        let newyork   = locationGraph.addLocationVertex(name: "New York", latitude: 40.7128, longitude: -74.0060)
        let chicago   = locationGraph.addLocationVertex(name: "Chicago", latitude: 41.8781, longitude: -87.6298)
        let vancouver = locationGraph.addLocationVertex(name: "Vancouver", latitude: 49.2827, longitude: -123.1207)
        let monterrey = locationGraph.addLocationVertex(name: "Monterrey", latitude: 25.6866, longitude: -100.3161)
        
        let startVertex = newyork
        let endVertex = vancouver
        startVertex.h = Int(startVertex.coordinates.distance(from: endVertex.coordinates))
        chicago.h = Int(chicago.coordinates.distance(from: endVertex.coordinates))
        monterrey.h = Int(monterrey.coordinates.distance(from: endVertex.coordinates))
        
        let distanceFromNewYorkToChicago = newyork.coordinates.distance(from: chicago.coordinates)
        locationGraph.addEdge(from: newyork, to: chicago, with: Int(distanceFromNewYorkToChicago))
        
        let distanceFromNewYorkToMonterrey = newyork.coordinates.distance(from: monterrey.coordinates)
        locationGraph.addEdge(from: newyork, to: monterrey, with: Int(distanceFromNewYorkToMonterrey))
        
        let distanceFromChicagoToVancouver = chicago.coordinates.distance(from: vancouver.coordinates)
        locationGraph.addEdge(from: chicago, to: vancouver, with: Int(distanceFromChicagoToVancouver))
        
        let distanceFromVancouverToMonterrey = vancouver.coordinates.distance(from: monterrey.coordinates)
        locationGraph.addEdge(from: vancouver, to: monterrey, with: Int(distanceFromVancouverToMonterrey))
        
        locationGraph.canvas.forEach { (locationVertex) in
            let annotation = MKPointAnnotation()
            annotation.title = locationVertex.key
            annotation.coordinate = locationVertex.coordinates
            
            self.mapView.addAnnotation(annotation)
            
        }
        
        let path = try! locationGraph.aStarSearch(from: startVertex, to: endVertex)
        path.forEach { vertex in
            print(vertex.description)
        }
        
        let locations = path.map( { $0.coordinates } )
        let geodesicPolyline = MKGeodesicPolyline(coordinates: locations, count: locations.count)
        mapView.addOverlay(geodesicPolyline)
        
        self.flightpathPolyline = MKGeodesicPolyline(coordinates: locations, count: 3)

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
            testlineRenderer.strokeColor = Colors.lightOrange.value
            testlineRenderer.lineWidth = 1.5
            return testlineRenderer
        }
        fatalError("Something wrong...")
    }
}

protocol CoordinateComputation {
    func addLocationVertex(name: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Vertex
}

extension Graph: CoordinateComputation {
    
    func addLocationVertex(name: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Vertex {
        let locationVertex: Vertex = Vertex(name: name, latitude: latitude, longitude: longitude)
        canvas.append(locationVertex)
        return locationVertex
    }
    
}

protocol Positionable {
    var coordinates: CLLocationCoordinate2D { get set }
}

extension Vertex: Positionable {
    private static var _myComputedProperty = [String: CLLocationCoordinate2D]()
    
    var coordinates: CLLocationCoordinate2D {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return Vertex._myComputedProperty[tmpAddress] ?? CLLocationCoordinate2D()
        }
        
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            Vertex._myComputedProperty[tmpAddress] = newValue
        }
    }
    
    convenience init(name: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.init()
        key = name
        coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
    }
    
}

extension CLLocationCoordinate2D {
    
    func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
        let destination = CLLocation(latitude: from.latitude, longitude: from.longitude)
        return CLLocation(latitude: self.latitude, longitude: self.longitude).distance(from: destination)
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

