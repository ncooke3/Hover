//
//  Graph.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 8/30/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import Foundation

enum GraphError: Error {
    case emptyGraph
    case vertexNotInGraph
}

public class Graph {

    var canvas: [Vertex]
    var isDirected: Bool
    
    init() {
        self.canvas = [Vertex]()
        self.isDirected = false
    }
    
    /// Creates a vertex with provided key and adds it to graph's canvas.
    func addVertex(key: String) -> Vertex {
        // create vertex
        let vertex: Vertex = Vertex()
        vertex.key = key
        
        canvas.append(vertex)
        
        return vertex
    }
    
    /// Create an edge between two provided vertices.
    func addEdge(from startVertex: Vertex, to endVertex: Vertex, with length: Int) {
        
        let edge: Edge = Edge()
        
        edge.anchor = endVertex
        edge.length = length
        startVertex.edges.append(edge)
        
        if isDirected == false {
            let reverseEdge: Edge = Edge()
            reverseEdge.anchor = startVertex
            reverseEdge.length = length
            endVertex.edges.append(reverseEdge)
        }

    }
    
    /// Search graph from start vertex to end vertex and return path taken.
    func aStarSearch(from startVertex: Vertex, to endVertex: Vertex) throws -> [Vertex] {
        
        // Handle Errors
        guard self.canvas.isNotEmpty() else { throw GraphError.emptyGraph }
        
        let graphDoesNotContainStartVertex = self.canvas.contains { $0.key == startVertex.key }
        guard graphDoesNotContainStartVertex else { throw GraphError.vertexNotInGraph }
  
        let graphDoesNotContainEndVertex = self.canvas.contains { $0.key == endVertex.key }
        guard graphDoesNotContainEndVertex else { throw GraphError.vertexNotInGraph }
        
        // Begin Algorithm
        var unvisited: [Vertex] = [Vertex]()
        var visited: [Vertex]   = [Vertex]()
        
        unvisited.append(startVertex)
        
        while unvisited.isNotEmpty() {
            
            // Get the vertex in the unvisited list with the least f value
            var currentVertex: Vertex   = unvisited.first! // unvisited.isNotEmpty at the moment within the loop
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
                var path: [Vertex] = [Vertex]()
                var backtrackingVertex: Vertex? = currentVertex
                while backtrackingVertex != nil {
                    path.append(backtrackingVertex!)
                    backtrackingVertex = backtrackingVertex?.parent
                }
                return path.reversed()
            }
            
            // Get neighbors of currentVertext
            var neighborsOfCurrentVertext: [(Vertex, Int)] = [(Vertex, Int)]()
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
                for unvisitedVertext in unvisited {
                    if neighbor.key == unvisitedVertext.key && neighbor.g >= unvisitedVertext.g {
                        doesUnvisitedContainNeighbor = true // and we dont want to update its values bc this one is farther
                    } else {
                        // probably should update values
                    }
                }
                
                guard doesUnvisitedContainNeighbor == false else { continue }
                
                // Finally, add neighbor to unvisited list
                unvisited.append(neighbor)
                
            }
            
        }
        
        print("🏝 The node you are looking for was not reachable.")
        return [Vertex]()
    }
    
    
    
    
}

extension Array {
    
    func isNotEmpty() -> Bool {
        return !self.isEmpty
    }
    
}
