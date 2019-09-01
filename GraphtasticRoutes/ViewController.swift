//
//  ViewController.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 8/30/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import UIKit
import MapKit

    // New York  40.7128° N, 74.0060° W
    // Vancouver 49.2827° N, 123.1207° W
    // Monterrey 25.6866° N, 100.3161° W

class ViewController: UIViewController, MKMapViewDelegate {

    var mapView = MKMapView()
    var locationGraph: Graph!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.frame = view.frame
        view.addSubview(mapView)
        
        mapView.delegate = self
        
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
        let polyline = MKPolyline(coordinates: locations, count: locations.count)
        mapView.addOverlay(polyline)
        
    }

    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }

        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let testlineRenderer = MKPolylineRenderer(polyline: polyline)
            testlineRenderer.strokeColor = Colors.orange.value
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




