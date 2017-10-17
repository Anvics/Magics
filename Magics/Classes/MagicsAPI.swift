//
//  MagicsAPI.swift
//  Magics
//
//  Created by Nikita Arkhipov on 25.08.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

public class MagicsAPI{
    public var baseURL: String { return "" }
    public var parser: MagicsParser = MagicsParser()
    
    public func modify<T: MagicsInteractor>(request: URLRequest, interactor: T) -> URLRequest { return request }
    
    public func hasErrorFor<T: MagicsInteractor>(json: MagicsJSON?, response: URLResponse?, error: Error?, interactor: T) -> Error?{ return nil }
    
    public func process<T: MagicsInteractor>(json: MagicsJSON, response: URLResponse?, interactor: T){ }
    public func completed<T: MagicsInteractor>(interactor: T, json: MagicsJSON?, response: URLResponse?){ }
    
    public func process<T: MagicsInteractor>(error: Error, response: URLResponse?, interactor: T){ }
    
    public func finish<T: MagicsInteractor>(interactor: T, error: Error?, response: URLResponse?, completion: ((T, Error?) -> Void)?){ completion?(interactor, error) }
}

//MARK: - Update & Extract
public extension MagicsAPI{
    public func update(model: MagicsModel, with json: MagicsJSON){
        let parserToUse = type(of: model).customParser ?? parser
        parserToUse.update(object: model as! NSObject, with: json, api: self)
        model.update(key: nil, json: json, api: self)
    }
    
    public func arrayFrom<T: MagicsModel>(json: MagicsJSON) -> [T]{
        let p = T.customParser ?? parser
        return p.extractFrom(json: json, objectsOfType: T.self, api: self) as! [T]
    }
    
    public func objectFrom<T: MagicsModel>(json: MagicsJSON) -> T{
        let model = T.init()
        update(model: model, with: json)
        return model
    }
}

//MARK: - perform
public extension MagicsAPI{
    public func interact<T: MagicsInteractor>(_ interactor: T, completion: ((T, Error?) -> Void)? = nil){
        let urlString = (baseURL + interactor.relativeURL).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        guard let urlStringU = urlString, let url = URL(string: urlStringU) else { fatalError() }
        var request = URLRequest(url: url)
        request.httpMethod = interactor.method.rawValue
        request = modify(request: request, interactor: interactor)
        request = interactor.modify(request: request)
//        request.httpBody
        
        MagicsJSON.loadWith(request: request) { json, response, error in
            if let error = self.hasErrorFor(json: json, response: response, error: error, interactor: interactor) ?? interactor.hasErrorFor(json: json, response: response, error: error){
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
                        interactor.process(json: jsonU, response: response, api: self)
                        if let m = interactor as? MagicsModel { self.update(model: m, with: jsonU) }
                    }
                }
                self.performOn(thread: interactor.completionThread) {
                    self.completed(interactor: interactor, json: json, response: response)
                    interactor.completedWith(json: json, response: response)
                    
                    self.finish(interactor: interactor, error: error, response: response, completion: completion)
                }
            }
        }
    }
    
//    func perform(_ pipe: MagicsPipe, completion: ((MagicsPipe, Error?) -> Void)? = nil){
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
