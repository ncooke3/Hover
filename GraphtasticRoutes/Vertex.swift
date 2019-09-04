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
    var edges: Set<Edge>
    weak var parent: Vertex?
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
        self.edges = Set<Edge>()
    }
    
}

extension Vertex: Equatable {
    static func == (lhs: Vertex, rhs: Vertex) -> Bool {
        return lhs.key == rhs.key //&& lhs.edges == rhs.edges
    }
}

extension Vertex: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}
