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
    case startVertexNotInGraph
    case goalVertexNotInGraph
    
    public var errorDescription: String? {
        switch self {
        case .emptyGraph:
            return NSLocalizedString("😅 The graph is empty.", comment: "The graph you are searching through is actually empty! Add vertices to continue.")
        case .startVertexNotInGraph:
            return NSLocalizedString("😅 The start vertex is not in the graph.", comment: "The start vertex does not seem to be in the graph... check your call to performAStar!")
        case .goalVertexNotInGraph:
            return NSLocalizedString(" 😅 The goal vertex is not in the graph.", comment: "The goal vertex does not seem to be in the graph... check your call to performAStar!")
        }
    }
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
        startVertex.edges.insert(edge)
        
        if isDirected == false {
            let reverseEdge: Edge = Edge()
            reverseEdge.anchor = startVertex
            reverseEdge.length = length
            endVertex.edges.insert(reverseEdge)
        }

    }
    
    /// Search graph from start vertex to end vertex and return path taken.
    func aStarSearch(from startVertex: Vertex, to endVertex: Vertex) throws -> [Vertex] {
        
        // Handle Errors
        guard self.canvas.isNotEmpty() else { throw GraphError.emptyGraph }
        
        let graphDoesNotContainStartVertex = self.canvas.contains { $0.key == startVertex.key }
        guard graphDoesNotContainStartVertex else { throw GraphError.startVertexNotInGraph }
  
        let graphDoesNotContainEndVertex = self.canvas.contains { $0.key == endVertex.key }
        guard graphDoesNotContainEndVertex else { throw GraphError.goalVertexNotInGraph }
        
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
        return [Vertex]()
    }
    
}

extension Collection {
    
    func isNotEmpty() -> Bool {
        return !self.isEmpty
    }
    
}
