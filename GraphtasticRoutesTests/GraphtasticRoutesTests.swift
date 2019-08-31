//
//  GraphtasticRoutesTests.swift
//  GraphtasticRoutesTests
//
//  Created by Nicholas Cooke on 8/30/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import XCTest
@testable import GraphtasticRoutes

class GraphtasticRoutesTests: XCTestCase {
    
    var testGraph: Graph!

    override func setUp() {
        super.setUp()
        
        testGraph = Graph()
        
    }

    override func tearDown() {
       super.tearDown()
        
        testGraph = nil
    }
    
    func testGraphWithOneVertex() {
        testGraph.addVertex(key: "A")
        
        let path: [Vertex] = testGraph.aStarSearch(from: testGraph.canvas[0], to: testGraph.canvas[0])
        
        XCTAssert(path[0].key == "A")
    }

    func testMediumGraph() {
        addSampleVerticesAndEdgesTo(a: testGraph)
        let path: [Vertex] = testGraph.aStarSearch(from: testGraph.canvas[0], to: testGraph.canvas[9])
        let correctValues: [String] = ["A", "F", "G", "I", "J"]
        for (index, vertex) in path.enumerated() {
            XCTAssert(correctValues[index] == vertex.key)
        }

    }
    
    func testSmallGraph() {
        testSmallGraph(a: testGraph)
        let path: [Vertex] = testGraph.aStarSearch(from: testGraph.canvas[0], to: testGraph.canvas[6])

        let correctValues: [String] = ["A", "C", "B", "D", "E", "Z"]
        for (index, vertex) in path.enumerated() {
            XCTAssert(correctValues[index] == vertex.key)
        }
    }

    
    func addSampleVerticesAndEdgesTo(a graph: Graph) {
        // add vertices
        let vertexA: Vertex = graph.addVertex(key: "A")
        vertexA.h = 10
        
        let vertexB: Vertex = graph.addVertex(key: "B")
        vertexB.h = 8
        
        let vertexC: Vertex = graph.addVertex(key: "C")
        vertexC.h = 5
        
        let vertexD: Vertex = graph.addVertex(key: "D")
        vertexD.h = 7
        
        let vertexE: Vertex = graph.addVertex(key: "E")
        vertexE.h = 3
        
        let vertexF: Vertex = graph.addVertex(key: "F")
        vertexF.h = 6
        
        let vertexG: Vertex = graph.addVertex(key: "G")
        vertexG.h = 5
        
        let vertexH: Vertex = graph.addVertex(key: "H")
        vertexH.h = 3
        
        let vertexI: Vertex = graph.addVertex(key: "I")
        vertexI.h = 1
        
        let vertexJ: Vertex = graph.addVertex(key: "J")
        vertexJ.h = 0
        
        // add edges
        graph.addEdge(from: vertexA, to: vertexB, with: 6)
        graph.addEdge(from: vertexA, to: vertexF, with: 3)
        graph.addEdge(from: vertexB, to: vertexC, with: 3)
        graph.addEdge(from: vertexB, to: vertexD, with: 2)
        graph.addEdge(from: vertexC, to: vertexD, with: 1)
        graph.addEdge(from: vertexC, to: vertexE, with: 5)
        graph.addEdge(from: vertexD, to: vertexE, with: 8)
        graph.addEdge(from: vertexE, to: vertexI, with: 5)
        graph.addEdge(from: vertexE, to: vertexJ, with: 5)
        graph.addEdge(from: vertexF, to: vertexG, with: 1)
        graph.addEdge(from: vertexF, to: vertexH, with: 7)
        graph.addEdge(from: vertexG, to: vertexI, with: 3)
        graph.addEdge(from: vertexH, to: vertexI, with: 2)
        graph.addEdge(from: vertexI, to: vertexJ, with: 3)
        
    }
    
    func testSmallGraph(a graph: Graph) {
        // add vertices
        let vertexA: Vertex = graph.addVertex(key: "A")
        vertexA.h = 14
        
        let vertexB: Vertex = graph.addVertex(key: "B")
        vertexB.h = 12
        
        let vertexC: Vertex = graph.addVertex(key: "C")
        vertexC.h = 11
        
        let vertexD: Vertex = graph.addVertex(key: "D")
        vertexD.h = 6
        
        let vertexE: Vertex = graph.addVertex(key: "E")
        vertexE.h = 4
        
        let vertexF: Vertex = graph.addVertex(key: "F")
        vertexF.h = 11
        
        let vertexZ: Vertex = graph.addVertex(key: "Z")
        vertexZ.h = 0
        
        // add edges
        graph.addEdge(from: vertexA, to: vertexB, with: 4)
        graph.addEdge(from: vertexA, to: vertexC, with: 3)
        graph.addEdge(from: vertexB, to: vertexE, with: 12)
        graph.addEdge(from: vertexB, to: vertexF, with: 5)
        graph.addEdge(from: vertexC, to: vertexD, with: 7)
        graph.addEdge(from: vertexC, to: vertexE, with: 10)
        graph.addEdge(from: vertexD, to: vertexE, with: 2)
        graph.addEdge(from: vertexE, to: vertexZ, with: 5)
        
    }

}
