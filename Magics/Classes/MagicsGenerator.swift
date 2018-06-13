//
//  MagicsGenerator.swift
//  Pods
//
//  Created by Nikita Arkhipov on 22.11.2017.
//
//

import Foundation

public class MagicsGenerator: NSObject, MagicsInteractor{
    
    public let relativeURL: String
    public let method: MagicsMethod
    public let api = MagicsAPI()
    
    let modifyRequestBlock: ((URLRequest) -> URLRequest)?
    let inputObject: String
    let initMethod: String
    let interactorModifyRequestBody: String
    let ignoredProperties: [String]
    
    public init(URL: String, method: MagicsMethod = .get, requestJSONParams: [String: Any]? = nil, ignoredProperties: [String] = []) {
        self.relativeURL = URL
        self.method = method
        self.ignoredProperties = ignoredProperties
        
        if let params = requestJSONParams{
            self.modifyRequestBlock = { request in
                var newRequest = request
                newRequest.setJSONBody(with: params)
                return newRequest
            }
            var keys = ""
            var requestKeys = ""
            for (key, value) in params{
                keys += "   let \(key): \(type(of: value))\n"
                if requestKeys != "" { requestKeys += ",\n" }
                requestKeys += "          \"\(key)\": inputObject.\(key)"
            }
            let name = relativeURL.components(separatedBy: "/").last!.capitalized + "Interactor"
            self.inputObject = "struct \(name)Input{\n\(keys)}"
            self.initMethod = "   let inputObject: \(name)Object\n\n   override init() { fatalError() }\n\n   init(input: \(name)Input){\n       inputObject = input\n   }\n\n"
            self.interactorModifyRequestBody = "   func modify(request: URLRequest) -> URLRequest{\n       var req = request\n       req.setJSONBody(with: [\n\(requestKeys)\n         ])\n       return req\n    }"
        }else{
            self.modifyRequestBlock = nil
            inputObject = ""
            self.interactorModifyRequestBody = ""
            self.initMethod = "   override required init() {}\n"
        }
        
    }
    
    private func className() -> String{
        return relativeURL.components(separatedBy: "/").last!.capitalized + "Interactor"
    }
    
    private var generatedClassesStrings = [String]()
    private var classNames = [String]()
    
    public func process(key: String?, json: MagicsJSON, api: MagicsAPI){
        print("-------------------------------------------")
        print(inputObject + "\n")
        print("class \(className()): NSObject, MagicsInteractor, MagicsModel {")
        print("   var relativeURL: String { return \"\(relativeURL)\" }")
        print("   var method: MagicsMethod { return .\(method) }\n")
//        var process = ""
        if json.isArray || json.isBaseDictionaryArray{
            print("    @objc dynamic var items = [\(addClassFrom(json: json, name: "item", hasKey: false))]()")
//            process = "    func process(json: MagicsJSON, response: URLResponse?, api: MagicsAPI){\n    items = api.arrayFrom(json: json)\n }"
        }else{
            print(classBodyFrom(json: json))
        }
        
        print(initMethod + interactorModifyRequestBody)
        print("}\n\n")
        generatedClassesStrings.reversed().forEach{ print($0) }
    }
    
    private func classBodyFrom(json: MagicsJSON, hasKey: Bool = false) -> String{
        guard json.isDictionary else { fatalError() }
        var body = ""
        json.enumerate { key, json in
            guard let key = key else { fatalError() }
            if self.ignoredProperties.contains(key) { return }
            body += "   @objc dynamic var \(key) = "
            if json.isArray || json.isBaseDictionaryArray{
                body += "[\(self.addClassFrom(json: json, name: key.dropLastS(), hasKey: json.isBaseDictionaryArray))]()"
            }else if json.isDictionary{
                let className = addClassFrom(json: json, name: key, hasKey: false)
                body += "\(className)()"
            }else{
                body += json.baseValueString()
            }
            body += "\n"
        }
        
        if hasKey {
            let keyName = json["id"] == nil ? "id" : "name"
            body += "   var \(keyName) = \"\"\n\n"
            body += "   func update(key: String?, json: MagicsJSON, api: MagicsAPI){\n if let key = key { \(keyName) = key }\n  }\n"
        }
        
        return body
    }
    
    private func jsonDictToUse(json: MagicsJSON) -> MagicsJSON?{
        if !json.isBaseDictionaryArray { return json }
        guard let dict = json.dictionary, dict.allKeys.count > 0 else { return nil }
        return MagicsJSON(data: dict[dict.allKeys[0]]!)
    }
    
    private func addClassFrom(json: MagicsJSON, name: String, hasKey: Bool) -> String{
        var classString = ""
        guard let jsonToUse = (json.isDictionary ? jsonDictToUse(json: json) : json.firstArrayElement) else { return "#empty#" }
        let className = "\(name.capitalized)Model"
        if classNames.contains(className) { return className }
        classNames.append(className)
        
        classString += "public class \(className): NSObject, MagicsModel{\n"
        classString += classBodyFrom(json: jsonToUse, hasKey: hasKey)
        classString += "   override required public init() {}\n}\n"
        
        generatedClassesStrings.append(classString)
        
        return className
    }
    
    public func process(error: Error, response: URLResponse?){
        print("\(relativeURL) failed")
    }
    
    public func completedWith(json: MagicsJSON?, response: URLResponse?){
        print("----------------------")
        //        print(json)
        //        print(response)
    }
    
    public func modify(request: URLRequest) -> URLRequest {
        if let modifyRequest = modifyRequestBlock{
            return modifyRequest(request)
        }
        return request
    }
}

extension MagicsJSON{
    var isBaseDictionaryArray: Bool{
        guard isDictionary else { return false }
        var isBase = true
        enumerate { _, json in
            if !json.isDictionary { isBase = false }
        }
        return isBase
    }
    
    var firstArrayElement: MagicsJSON? {
        guard let array = array, array.count > 0 else { return nil }
        return MagicsJSON(data: array[0])
    }
    
    fileprivate func baseValueString() -> String{
        if let data = data as? NSNumber{
            let type = CFNumberGetType(data as CFNumber)
            switch type {
            case .intType, .nsIntegerType, .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type: return "0"
            case .doubleType, .floatType, .cgFloatType, .float32Type, .float64Type, .longType, .longLongType: return "0.0"
            default: break
            }
        }
        if data is Bool { return "true" }
        return "\"\""
    }
}
