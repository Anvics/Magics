//
//  MagicsAPI.swift
//  Magics
//
//  Created by Nikita Arkhipov on 25.08.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

open class MagicsAPI{
    open var baseURL: String { return "" }
    public var parser: MagicsParser = MagicsParser()
    
    public init(){}
    
    open func modify<T: MagicsInteractor>(request: URLRequest, interactor: T) -> URLRequest { return request }
    
    open func interact<T: MagicsInteractor>(_ interactor: T, completion: ((MagicsError?) -> Void)? = nil){
        perfromInteraction(interactor, completion: completion)
    }
    
    open func hasErrorFor<T: MagicsInteractor>(json: MagicsJSON?, response: URLResponse?, error: MagicsError?, interactor: T) -> MagicsError?{ return error }
    
    open func process<T: MagicsInteractor>(json: MagicsJSON, response: URLResponse?, interactor: T){ }
    open func completed<T: MagicsInteractor>(interactor: T, json: MagicsJSON?, response: URLResponse?){ }
    
    open func process<T: MagicsInteractor>(error: MagicsError, response: URLResponse?, interactor: T){ }
    
    open func finish<T: MagicsInteractor>(interactor: T, error: MagicsError?, response: URLResponse?, completion: ((MagicsError?) -> Void)?){ completion?(error) }
}

//MARK: - Update & Extract
public extension MagicsAPI{
    public func update(interactor: MagicsUpdatable, with json: MagicsJSON){
        parser.update(object: interactor as! NSObject, with: json, api: self)
        interactor.process(key: nil, json: json, api: self)
    }
    
    public func update(model: MagicsModel, with json: MagicsJSON){
        let p = type(of: model).customParser ?? parser
        p.update(object: model as! NSObject, with: json, api: self)
        model.process(key: nil, json: json, api: self)
    }
    
    public func arrayFrom<T: MagicsModel>(json: MagicsJSON) -> [T]{
        let p = T.customParser ?? parser
        return p.extractFrom(json: json, objectsOfType: T.self, api: self) as! [T]
    }
    
    public func objectFrom<T: MagicsModel>(json: MagicsJSON) -> T{
        let model = T.init()
        update(interactor: model, with: json)
        return model
    }
}

//MARK: - perform
public extension MagicsAPI{
    public func perfromInteraction<T: MagicsInteractor>(_ interactor: T, completion: ((MagicsError?) -> Void)? = nil){
        let urlString = (baseURL + interactor.relativeURL).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        guard let urlStringU = urlString, let url = URL(string: urlStringU) else { fatalError() }
        var request = URLRequest(url: url)
        request.httpMethod = interactor.method.rawValue
        request = modify(request: request, interactor: interactor)
        request = interactor.modify(request: request)
        
        MagicsJSON.loadWith(request: request) { json, response, baseError in
            let cerror = MagicsError.fromError(baseError)
            if let error = self.hasErrorFor(json: json, response: response, error: cerror, interactor: interactor) ?? interactor.hasErrorFor(json: json, response: response, error: cerror){
                self.performOn(thread: interactor.processThread) {
                    self.process(error: error, response: response, interactor: interactor)
                    interactor.process(error: error, response: response)
                }
                self.performOn(thread: interactor.completionThread) {
                    self.finish(interactor: interactor, error: error, response: response, completion: completion)
                }
            }else{
                if let jsonU = json{
                    self.performOn(thread: interactor.processThread) {
                        self.process(json: jsonU, response: response, interactor: interactor)
                        self.update(interactor: interactor, with: jsonU)
                    }
                }
                self.performOn(thread: interactor.completionThread) {
                    self.completed(interactor: interactor, json: json, response: response)
                    interactor.completedWith(json: json, response: response)
                    
                    self.finish(interactor: interactor, error: cerror, response: response, completion: completion)
                }
            }
        }

    }
    
//    func perform(_ pipe: MagicsPipe, completion: ((MagicsPipe, MagicsError?) -> Void)? = nil){
//        func performAt(index: Int){
//            let interactor = pipe.interactors[index]
//            perform(interactor) { _, error in
//                if let e = error { completion?(pipe, e) }
//                else{
//                    if index < pipe.interactors.count - 2 { performAt(index: index + 1) }
//                    else{ completion?(pipe, nil) }
//                }
//            }
//        }
//        
//        performAt(index: 0)
//    }
    
}

public extension MagicsAPI{
    fileprivate func performOn(thread: MagicsThread, block: @escaping () -> ()){
        switch thread {
        case .main: DispatchQueue.main.async(execute: block)
        case .background: DispatchQueue.global().async(execute: block)
        }
    }
}
