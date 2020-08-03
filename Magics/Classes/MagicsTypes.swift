//
//  MagicsMethod.swift
//  Magics
//
//  Created by Nikita Arkhipov on 25.08.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

public enum MagicsMethod: String {
    case get = "GET"
    case post = "POST"
    case update = "UPDATE"
    case delete = "DELETE"
    case patch = "PATCH"
}

public enum MagicsThread{
    case main
    case background
}
