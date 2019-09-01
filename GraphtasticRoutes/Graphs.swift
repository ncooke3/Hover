//
//  Graphs.swift
//  GraphtasticRoutes
//
//  Created by Nicholas Cooke on 9/1/19.
//  Copyright © 2019 Nicholas Cooke. All rights reserved.
//

import Foundation

enum Graphs {
    
    case World
    case NorthAmerica
    case GeorgiaTech
    case Custom(adjacencyList: [Vertex : [Vertex]])

    var graph: Graph {
        
        switch self {
        case .World:
            return WorldGraph.graph
        case .NorthAmerica:
            return NorthAmericaGraph.graph
        case .GeorgiaTech:
            return GeorgiaTechGraph.graph
        case .Custom(let adjacencyList):
            return Graph(with: adjacencyList)
        }
    }
    
}

struct WorldGraph {
    
    static var graph: Graph {
        return Graph(with: adjacencyList)
    }
    
    static let adjacencyList: [Vertex : [Vertex]] = [
        Amsterdam   : [Athens, Barcelona],
        Athens      : [Atlanta],
        Auckland    : [Perth],
        Barcelona   : [NewYork],
        Beijing     : [Moscow, Auckland],
        Bombay      : [London],
        BuenosAires : [Miami, Medellin],
        Cairo       : [Barcelona, Bombay],
        CapeTown    : [BuenosAires, Perth],
        Dublin      : [Atlanta],
        Havana      : [Miami],
        Helsinki    : [London, Moscow],
        HongKong    : [Moscow, Bombay, Cairo],
        London      : [NewYork, Dublin],
        Moscow      : [],
        Medellin    : [MexicoCity, Atlanta, Miami],
        Perth       : [HongKong, Bombay],
        Atlanta     : [Amsterdam],
        NewYork     : [Atlanta],
        LosAngeles  : [HongKong, Beijing],
        MexicoCity  : [LosAngeles, Amsterdam],
        Toronto     : [NewYork, LosAngeles, Atlanta],
        Miami       : [Toronto, Atlanta]
    ]
    
}


struct NorthAmericaGraph {
    
    static var graph: Graph {
        return Graph(with: adjacencyList)
    }
    
    static let adjacencyList: [Vertex : [Vertex]] = [
        NewYork     : [Chicago, Toronto, Atlanta],
        Chicago     : [Toronto, Miami],
        Vancouver   : [SanFrancisco, LosAngeles,  Toronto],
        Monterrey   : [LosAngeles, Cancun, Atlanta],
        SanFrancisco: [Denver, MexicoCity],
        LosAngeles  : [Denver, Atlanta],
        Toronto     : [NewYork, LosAngeles, Chicago],
        MexicoCity  : [Cancun, LosAngeles, Monterrey],
        Atlanta     : [NewYork, LosAngeles, Chicago, Miami, Monterrey],
        SaltLake    : [Denver, Atlanta],
        Denver      : [SaltLake, Vancouver],
        Miami       : [Atlanta, NewYork, Toronto],
        Cancun      : [Atlanta, MexicoCity],
        Washington  : [Atlanta],
    ]

}


struct GeorgiaTechGraph {
    
    static var graph: Graph {
        return Graph(with: adjacencyList)
    }
    
    static let adjacencyList: [Vertex : [Vertex]] = [
        TechTower    : [],
        Clough       : [],
        Paper        : [],
        Ferst        : [],
        Nave         : [],
        WestVillage  : [],
        CRC          : [],
        Klaus        : [],
        TechSquare   : [],
        HomePark     : [],
        BobbyDodd    : [],
        Howey        : [],
        Cookout      : [],
        TheVarsity   : [],
    ]
    
}



extension Graph {
    
    convenience init(with adjacencyList: [Vertex : [Vertex]]) {
        self.init()
        for vertex in adjacencyList {
            self.canvas.append(vertex.key)
            
            for neighbor in vertex.value {
                let distanceFromNeigbor = vertex.key.coordinates.distance(from: neighbor.coordinates)
                self.addEdge(from: vertex.key, to: neighbor, with: Int(distanceFromNeigbor))
            }
        }
    }
    
}

