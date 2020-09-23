//
//  MagicsError.swift
//  TestFrameworksProject
//
//  Created by Nikita Arkhipov on 04.05.2018.
//  Copyright © 2018 Nikita Arkhipov. All rights reserved.
//

import Foundation

open class MagicsError: Error {
    public let code: Int
    public let message: String

    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
    open var isNoNetwork: Bool { code == -1009 }
    open var couldNotConnectToServer: Bool { code == -1004 }
    
    public static func fromError(_ error: Error?) -> MagicsError?{
        guard let error = error as NSError? else { return nil }
        return MagicsError(code: error.code, message: error.description)
    }
    
    public static func fromJSON(_ json: MagicsJSON?) -> MagicsError?{
        if let json = json,
            let status = json["status"]?.string,
            let code = json["code"]?.int,
            let message = json["message"]?.string,
            status == "error"{
            return MagicsError(code: code, message: message)
        }
        return nil
    }
}

extension MagicsError: Equatable, CustomStringConvertible{
    public static func == (lhs: MagicsError, rhs: MagicsError) -> Bool{
        return lhs.code == rhs.code
    }
    
    public var description: String{
        return "\(code): \(message)"
    }
}
