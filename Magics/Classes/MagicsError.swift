//
//  MagicsError.swift
//  TestFrameworksProject
//
//  Created by Nikita Arkhipov on 04.05.2018.
//  Copyright © 2018 Nikita Arkhipov. All rights reserved.
//

import Foundation

public class MagicsError: Error {
    let code: Int
    let message: String

    init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
    static func fromError(_ error: Error?) -> MagicsError?{
        guard let error = error as NSError? else { return nil }
        return MagicsError(code: error.code, message: error.description)
    }
}

extension MagicsError: Equatable{
    public static func == (lhs: MagicsError, rhs: MagicsError) -> Bool{
        return lhs.code == rhs.code
    }
}
