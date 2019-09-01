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
    var locationGraph: LocationGraph!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.frame = view.frame
        view.addSubview(mapView)
        
        mapView.delegate = self
        
        locationGraph = LocationGraph()
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
        
        locationGraph.locationCanvas.forEach { (locationVertex) in
            let annotation = MKPointAnnotation()
            annotation.title = locationVertex.key
            annotation.coordinate = locationVertex.coordinates
            
            self.mapView.addAnnotation(annotation)
            
        }
        
        let path = try! locationGraph.aStarSearch(from: startVertex, to: endVertex)
        path.forEach { vertex in
            print(vertex.description)
        }
        
        let locations = path.map( { $0.coordinates! } )
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


class LocationVertex {
    
    var coordinates: CLLocationCoordinate2D!
    
    var key: String?
    var edges: [LocationEdge]
    var parent: LocationVertex?
    var g: Int = 0
    var h: Int = 0
    var f: Int = 0
    
    init(name: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.key = name
        self.edges = [LocationEdge]()
    }

    
    var description: String {
        return """
        Node: \(key!)
        • g: \(g)
        • h: \(h)
        • f: \(f) \n
        """
    }
    
    init() {
        self.edges = [LocationEdge]()
    }
    
}

class LocationEdge {
    
    var anchor: LocationVertex
    var length: Int
    
    init() {
        self.length = 0
        self.anchor = LocationVertex()
    }
    
}

class LocationGraph {
    
    var locationCanvas: [LocationVertex]
    var isDirected: Bool
    
    init() {
        self.locationCanvas = [LocationVertex]()
        self.isDirected = false
    }
    
    /// Creates a vertex with provided key and adds it to graph's canvas.
    func addLocationVertex(name: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> LocationVertex {
        let locationVertex: LocationVertex = LocationVertex(name: name, latitude: latitude, longitude: longitude)
        
        locationCanvas.append(locationVertex)
        
        return locationVertex
        
    }
    
    /// Create an edge between two provided vertices.
    func addEdge(from startVertex: LocationVertex, to endVertex: LocationVertex, with length: Int) {
        
        let edge: LocationEdge = LocationEdge()
        
        edge.anchor = endVertex
        edge.length = length
        startVertex.edges.append(edge)
        
        if isDirected == false {
            let reverseEdge: LocationEdge = LocationEdge()
            reverseEdge.anchor = startVertex
            reverseEdge.length = length
            endVertex.edges.append(reverseEdge)
        }
        
    }
    
    /// Search graph from start vertex to end vertex and return path taken.
    func aStarSearch(from startVertex: LocationVertex, to endVertex: LocationVertex) throws -> [LocationVertex] {
        
        // Handle Errors
        guard self.locationCanvas.isNotEmpty() else { throw GraphError.emptyGraph }
        
        let graphDoesNotContainStartVertex = self.locationCanvas.contains { $0.key == startVertex.key }
        guard graphDoesNotContainStartVertex else { throw GraphError.vertexNotInGraph }
        
        let graphDoesNotContainEndVertex = self.locationCanvas.contains { $0.key == endVertex.key }
        guard graphDoesNotContainEndVertex else { throw GraphError.vertexNotInGraph }
        
        // Begin Algorithm
        var unvisited: [LocationVertex] = [LocationVertex]()
        var visited: [LocationVertex]   = [LocationVertex]()
        
        unvisited.append(startVertex)
        
        while unvisited.isNotEmpty() {
            
            // Get the vertex in the unvisited list with the least f value
            var currentVertex: LocationVertex   = unvisited.first! // unvisited.isNotEmpty at the moment within the loop
            var currentVertexIndex: Int = 0
            
            for (index, vertex) in unvisited.enumerated() {
                if vertex.f < currentVertex.f {
                    currentVertex      = vertex
                    currentVertexIndex = index
                }
            }
            
            // Remove from unvisited list and add to visited list
            unvisited.remove(at: currentVertexIndex)
            visited.append(currentVertex)
            
            // 🏁 Check if we found goal vertex
            if currentVertex.key == endVertex.key { // TODO: compute equality based on position?
                var path: [LocationVertex] = [LocationVertex]()
                var backtrackingVertex: LocationVertex? = currentVertex
                while backtrackingVertex != nil {
                    path.append(backtrackingVertex!)
                    backtrackingVertex = backtrackingVertex?.parent
                }
                return path.reversed()
            }
            
            // Get neighbors of currentVertext
            var neighborsOfCurrentVertext: [(LocationVertex, Int)] = [(LocationVertex, Int)]()
            for edge in currentVertex.edges {
                let neighborToCurrentVertex = (edge.anchor, edge.length)
                neighborsOfCurrentVertext.append(neighborToCurrentVertex)
            }
            
            // Iterate over neighborsOfCurrentVertext
            for (neighbor, lengthFromCurrentVertext) in neighborsOfCurrentVertext {
                
                // Break if neighbor is in visited list
                var doesVisitedContainNeighbor: Bool = false
                
                for visitedVertex in visited {
                    if neighbor.key == visitedVertex.key {
                        doesVisitedContainNeighbor = true
                    }
                }
                
                guard doesVisitedContainNeighbor == false else { continue }
                
                // Set the parent 👨‍👦
                neighbor.parent = currentVertex
                
                // Set the important values!
                neighbor.g = currentVertex.g + lengthFromCurrentVertext
                neighbor.h += 0
                neighbor.f = neighbor.g + neighbor.h
                
                // Is neighbor in in unvisited list?
                var doesUnvisitedContainNeighbor: Bool = false
                for (index, unvisitedVertext) in unvisited.enumerated() {
                    if neighbor.key == unvisitedVertext.key {
                        doesUnvisitedContainNeighbor = true
                        if neighbor.g < unvisitedVertext.g {
                            unvisited[index] = neighbor
                        }
                    }
                }
                
                guard doesUnvisitedContainNeighbor == false else { continue }
                
                // Finally, add neighbor to unvisited list
                unvisited.append(neighbor)
                
            }
            
        }
        
        print("🏝 The node you are looking for was not reachable.")
        return [LocationVertex]()
    }

}

extension CLLocationCoordinate2D {
    
    func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
        let destination = CLLocation(latitude: from.latitude, longitude: from.longitude)
        return CLLocation(latitude: self.latitude, longitude: self.longitude).distance(from: destination)
    }
    
}




