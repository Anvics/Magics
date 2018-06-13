//
//  File.swift
//  Magics
//
//  Created by Nikita Arkhipov on 05.09.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

public protocol MagicsUpdatable: NSObjectProtocol{
    /// Вызывается в случае успешного выполнения и если есть json. Выполняется на потоке, указанном в processThread
    func process(key: String?, json: MagicsJSON, api: MagicsAPI)
    
    func ignoredProperties() -> [String]
}

extension MagicsUpdatable{
    public func process(key: String?, json: MagicsJSON, api: MagicsAPI){ }
    
    public func ignoredProperties() -> [String] { return [] }
}

public protocol MagicsModel: MagicsUpdatable {
    static var customParser: MagicsParser? { get }
    
    init()
}

public extension MagicsModel{
    static var customParser: MagicsParser? { return nil }
}
