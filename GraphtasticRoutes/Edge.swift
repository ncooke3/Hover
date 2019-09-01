//
//  Edge.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 9/1/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import Foundation

class Edge {
    
    var anchor: Vertex
    var length: Int
    
    init() {
        self.length = 0
        self.anchor = Vertex()
    }
    
}

extension Edge: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.length)
    }
    
    static func == (lhs: Edge, rhs: Edge) -> Bool {
        return lhs.anchor == rhs.anchor && lhs.length == rhs.length
    }
}
