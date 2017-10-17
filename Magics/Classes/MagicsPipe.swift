//
//  MagicsPipe.swift
//  Magics
//
//  Created by Nikita Arkhipov on 25.08.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

class MagicsPipe {
    private(set) var interactors = [MagicsInteractor]()
    
    init(interactor: MagicsInteractor) {
        interactors.append(interactor)
    }
    
    func then(_ interactor: MagicsInteractor) -> MagicsPipe{
        interactors.append(interactor)
        return self
    }
}
