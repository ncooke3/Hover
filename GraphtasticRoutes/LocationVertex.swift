//
//  LocationVertex.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 9/1/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import MapKit

protocol Heuristable {
    func setHeuristicRelative(to vertex: Vertex)
}

extension Vertex: Heuristable {
    func setHeuristicRelative(to vertex: Vertex) {
        self.h = self.coordinates.distance(from: vertex.coordinates)
    }
}

protocol Positionable {
    var coordinates: CLLocationCoordinate2D { get set }
}

extension Vertex: Positionable {
    private static var computedCoordinates = [String: CLLocationCoordinate2D]()
    
    var coordinates: CLLocationCoordinate2D {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return Vertex.computedCoordinates[tmpAddress] ?? CLLocationCoordinate2D()
        }
        
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            Vertex.computedCoordinates[tmpAddress] = newValue
        }
    }
    
    convenience init(name: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.init()
        key = name
        coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
    }
    
}
