//
//  MagicsInteractor.swift
//  Magics
//
//  Created by Nikita Arkhipov on 25.08.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

public protocol MagicsInteractor{
    var relativeURL: String { get }
    
    var method: MagicsMethod { get }

    var processThread: MagicsThread { get }
    var completionThread: MagicsThread { get }
    
    /// Переопределите этот метод, чтобы изменить запрос: проставить хэдеры, задать httpBody
    func modify(request: URLRequest) -> URLRequest
    
    /// Если запрос прошел неуспешно, верните ошибку
    func hasErrorFor(json: MagicsJSON?, response: URLResponse?, error: Error?) -> Error?
    
    /// Вызывается в случае успешного выполнения и если есть json. Выполняется на потоке, указанном в processThread
    func process(json: MagicsJSON, response: URLResponse?, api: MagicsAPI)
    
    /// Всегда вызывается в случае успешного выполнения. Выполняется на потоке, указанном в completionThread
    func completedWith(json: MagicsJSON?, response: URLResponse?)
    
    /// Вызывается в случае неуспешного выполнения. Выполняется на потоке, указанном в processThread
    func process(error: Error, response: URLResponse?)
}

public extension MagicsInteractor{
    var method: MagicsMethod { return .get }
    var processThread: MagicsThread { return .main }
    var completionThread: MagicsThread { return .main }

    func modify(request: URLRequest) -> URLRequest { return request }
    
    func hasErrorFor(json: MagicsJSON?, response: URLResponse?, error: Error?) -> Error? { return error }
    
    func process(json: MagicsJSON, response: URLResponse?, api: MagicsAPI) { }
    func process(error: Error, response: URLResponse?) { }

    func completedWith(json: MagicsJSON?, response: URLResponse?) { }
}
