//
//  Vertex.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 8/30/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import Foundation

class Vertex {
    
    var key: String?
    var edges: [Edge]
    var g: Int = 0
    var h: Int = 0
    var f: Int = 0
    
    var description: String {
        return """
        Node: \(key!)
        • g: \(g)
        • h: \(h)
        • f: \(f) \n
        """
    }
    
    init() {
        self.edges = [Edge]()
    }
    
}

class Edge {
    
    var anchor: Vertex
    var length: Int
    
    init() {
        self.length = 0
        self.anchor = Vertex()
    }

}
