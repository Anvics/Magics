//
//  MagicsParser.swift
//  Magics
//
//  Created by Nikita Arkhipov on 25.08.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

open class MagicsParser{
    public static let shared = MagicsParser()
    
    open func valueFrom(json: MagicsJSON, forObject object: Any) -> Any?{
        if object is Int { return intFrom(json: json) }
        if object is Double { return doubleFrom(json: json) }
        if object is String { return stringFrom(json: json) }
        if object is Bool { return boolFrom(json: json) }
        return nil
    }
    
    open func intFrom(json: MagicsJSON) -> Int?{ return json.int }
    open func doubleFrom(json: MagicsJSON) -> Double?{ return json.double }
    open func stringFrom(json: MagicsJSON) -> String?{ return json.string }
    open func boolFrom(json: MagicsJSON) -> Bool?{ return json.bool }
    
    open func extractFrom(json: MagicsJSON, objectsOfType type: MagicsModel.Type, api: MagicsAPI) -> [NSObject]{
        var array = [NSObject]()
        json.enumerate { key, jsonData in
            let object = type.init()
            let nsobject = object as! NSObject
            self.update(object: nsobject, with: jsonData, api: api)
            object.process(key: key, json: jsonData, api: api)
            array.append(nsobject)
        }
        return array
    }
    
    open func update(object: NSObject, with json: MagicsJSON, api: MagicsAPI){
        updateMirror(mirror: Mirror(reflecting: object), object: object, json: json, api: api)
    }
    
    private func updateMirror(mirror: Mirror, object: NSObject, json: MagicsJSON, api: MagicsAPI){
        if let superMirror = mirror.superclassMirror, superMirror.subjectType != NSObject.self{
            updateMirror(mirror: superMirror, object: object, json: json, api: api)
        }
        let ignoredProperties = (object as? MagicsModel)?.ignoredProperties() ?? []
        for case let (label?, value) in mirror.children {
            if ignoredProperties.contains(label) { continue }
            guard let valueJson = json[label] else { continue }
            if value is [MagicsModel]{
                if let type = classTypeFromArray(value){
                    let array = extractFrom(json: valueJson, objectsOfType: type, api: api)
                    object.setValue(array, forKey: label)
                }
            }else if let m = value as? MagicsModel{
                api.update(model: m, with: valueJson)
            }else{
                if let v = valueFrom(json: valueJson, forObject: value){
                    object.setValue(v, forKey: label)
                }
            }
        }
    }

    private func classTypeFromArray(_ array: Any) -> MagicsModel.Type?{
        let arrayTypeName = "\(type(of: array))"
        let objectTypeName = arrayTypeName.mgcs_substring(from: 6, length: arrayTypeName.count - 7)
        return classTypeFrom(objectTypeName) as? MagicsModel.Type
    }
}

extension String{
    func dropLastS() -> String{
        return hasSuffix("s") ? mgcs_substring(to: count - 1) : self
    }
    
    func mgcs_index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func mgcs_substring(from: Int) -> String {
        let fromIndex = mgcs_index(from: from)
        return String(self[fromIndex..<endIndex])
    }

    func mgcs_substring(from: Int, length: Int) -> String {
        return mgcs_substring(from: from).mgcs_substring(to: length)
    }

    func mgcs_substring(to: Int) -> String {
        let toIndex = mgcs_index(from: to)
        return String(self[startIndex..<toIndex])
    }
    
    func mgcs_indexes(of string: String, options: CompareOptions = .literal) -> [Index] {
        var result: [Index] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range.lowerBound)
            start = range.upperBound
        }
        return result
    }
}

public extension URLRequest {
    mutating func setJSONBody(with parameters: [String: Any], shouldPrintJSON: Bool = false) {
        httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        if shouldPrintJSON { print((try? JSONSerialization.jsonObject(with: httpBody!, options: .allowFragments)) ?? "Failed to convert to json parameters: \(parameters)") }
        setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    mutating func setFormDataBody(with parameters: [String: String]) {
        httpBody = dataToFormData(params: parameters).data(using: .utf8)
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }
    
    func dataToFormData(params: [String : String]) -> String {
        var data = [String]()
        for(key, value) in params {
            data.append(key + "=\(value)")
        }
        let formData = data.map { String($0) }.joined(separator: "&")
        print("dataToFormData: " + formData)
        return formData
    }
}

func classTypeFrom(_ className: String) -> AnyClass!{
    if  let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
        // generate the full name of your class (take a look into your "YourProject-swift.h" file)
        let classStringName = "_TtC\(appName.count)\(appName)\(className.count)\(className)"
        // return the class!
        return NSClassFromString(classStringName)
    }
    return nil
}
