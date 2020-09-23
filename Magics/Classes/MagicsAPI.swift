//
//  MagicsAPI.swift
//  Magics
//
//  Created by Nikita Arkhipov on 25.08.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

open class MagicsAPI{
    open var baseURL: String = ""
    public var parser: MagicsParser = MagicsParser()
    
    public init(){}
    
    open func modify(request: URLRequest, interactor: MagicsInteractor) -> URLRequest { return request }
    
    open func interact(_ interactor: MagicsInteractor, completion: ((MagicsError?) -> Void)? = nil){
        perfromInteraction(interactor, completion: completion)
    }
    
    open func hasErrorFor(json: MagicsJSON?, response: URLResponse?, error: MagicsError?, interactor: MagicsInteractor) -> MagicsError?{ return error }
    
    open func process(json: MagicsJSON, response: URLResponse?, interactor: MagicsInteractor){ }
    open func completed(interactor: MagicsInteractor, json: MagicsJSON?, response: URLResponse?){ }
    
    open func process(error: MagicsError, response: URLResponse?, interactor: MagicsInteractor){ }
        
    open func isTokenError(_ error: MagicsError) -> Bool { return false }
    open func reauthorizeInteractor(for interactor: MagicsInteractor) -> MagicsInteractor? { return nil }
    open func minimumIntervalForReuthorization(for interactor: MagicsInteractor) -> TimeInterval{ return 60 }
    open func shouldReauthorize(interactor: MagicsInteractor, error: MagicsError) -> Bool { return true }
    
    open func reauthorizeStarted(interactor: MagicsInteractor, error: MagicsError) { }
    open func reauthorizeFailed(interactor: MagicsInteractor, error: MagicsError) { }
    open func reauthorizeSuccess(interactor: MagicsInteractor) { }
    
    open func shouldDelayAndRetry(for interactor: MagicsInteractor, error: MagicsError) -> Bool { return false }
    open func delayInterval(for interactor: MagicsInteractor, error: MagicsError) -> TimeInterval { 4.0 }
    
    typealias InteractionCompletion = (MagicsError?) -> Void
    private var lastReauthDate: Date?
    private var reauthQueue = [InteractionCompletion]()
    private var reathInteractor: MagicsInteractor?
    
    private func isRightTimingForReauth(for interactor: MagicsInteractor) -> Bool{
        guard let d = lastReauthDate else { return true }
        return Date().timeIntervalSince(d) > minimumIntervalForReuthorization(for: interactor)
    }

    open func finish(interactor: MagicsInteractor, error: MagicsError?, response: URLResponse?, completion: ((MagicsError?) -> Void)?){
        if reathInteractor?.isEqual(interactor) ?? false { //if thats reauth intercator – complete imidiately
            completion?(error)
            return
        }
        
        guard let err = error else{ //if everything is ok, nothing to check
            completion?(nil)
            return
        }
        
        if shouldDelayAndRetry(for: interactor, error: err){
            delay(by: delayInterval(for: interactor, error: err)) {
                self.interact(interactor, completion: completion)
            }
            return
        }
        
        guard isTokenError(err) && shouldReauthorize(interactor: interactor, error: err) else { completion?(err); return }
        // Token error section. Reauthorizing..
        
        reauthQueue.append { e in
            if e == nil { self.interact(interactor, completion: completion) }
            else { completion?(e) }
        }
        
        if reathInteractor != nil { return } //If already reauthroizing, we should wait for first reauth completion..
        guard let reauth = reauthorizeInteractor(for: interactor), isRightTimingForReauth(for: interactor) else {
            completion?(err)
            return
        }
        
        lastReauthDate = Date()
        reathInteractor = reauth
        interact(reauth) { e in
            if let e = e { self.reauthorizeFailed(interactor: interactor, error: e) }
            else { self.reauthorizeSuccess(interactor: interactor) }
            for c in self.reauthQueue{
                c(e)
            }
            self.reathInteractor = nil
            self.reauthQueue = []
        }
    }
    
    private func delay(by seconds: TimeInterval, block: @escaping () -> ()){
        let delayTime = DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            block()
        }
    }
}

//MARK: - Update & Extract
public extension MagicsAPI{
    func update(interactor: MagicsUpdatable, with json: MagicsJSON){
        parser.update(object: interactor as! NSObject, with: json, api: self)
        interactor.process(key: nil, json: json, api: self)
    }
    
    func update(model: MagicsModel, with json: MagicsJSON){
        let p = type(of: model).customParser ?? parser
        p.update(object: model as! NSObject, with: json, api: self)
        model.process(key: nil, json: json, api: self)
    }
    
    func arrayFrom<T: MagicsModel>(json: MagicsJSON) -> [T]{
        let p = T.customParser ?? parser
        return p.extractFrom(json: json, objectsOfType: T.self, api: self) as! [T]
    }
    
    func objectFrom<T: MagicsModel>(json: MagicsJSON) -> T{
        let model = T.init()
        update(interactor: model, with: json)
        return model
    }
}

//MARK: - perform
public extension MagicsAPI{
    func perfromInteraction(_ interactor: MagicsInteractor, completion: ((MagicsError?) -> Void)? = nil){
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
                    interactor.completedWith(json: json, response: response)
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
