//
//  File.swift
//  Magics
//
//  Created by Nikita Arkhipov on 05.09.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

public protocol MagicsModel: NSObjectProtocol {
    static var customParser: MagicsParser? { get }
    
    init()
    
    func update(key: String?, json: MagicsJSON, api: MagicsAPI)
    
    func ignoredProperties() -> [String]
}

public extension MagicsModel{
    static var customParser: MagicsParser? { return nil }
    
    func update(key: String?, json: MagicsJSON, api: MagicsAPI){ }
    
    func ignoredProperties() -> [String] { return [] }
}
