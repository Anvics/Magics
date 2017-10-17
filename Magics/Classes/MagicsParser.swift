//
//  MagicsParser.swift
//  Magics
//
//  Created by Nikita Arkhipov on 25.08.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

public class MagicsParser{
    public static let shared = MagicsParser()
    
    public func valueFrom(json: MagicsJSON, forObject object: Any) -> Any?{
        if object is Int { return intFrom(json: json) }
        if object is Double { return doubleFrom(json: json) }
        if object is String { return stringFrom(json: json) }
        return nil
    }
    
    public func intFrom(json: MagicsJSON) -> Int?{ return json.int }
    public func doubleFrom(json: MagicsJSON) -> Double?{ return json.double }
    public func stringFrom(json: MagicsJSON) -> String?{ return json.string }
    
    public func extractFrom(json: MagicsJSON, objectsOfType type: MagicsModel.Type, api: MagicsAPI) -> [NSObject]{
        var array = [NSObject]()
        json.enumerate { key, jsonData in
            let object = type.init()
            let nsobject = object as! NSObject
            self.update(object: nsobject, with: jsonData, api: api)
            object.update(key: key, json: jsonData, api: api)
            array.append(nsobject)
        }
        return array
    }
    
    public func update(object: NSObject, with json: MagicsJSON, api: MagicsAPI){
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
        let objectTypeName = arrayTypeName.mgcs_substring(from: 6, length: arrayTypeName.characters.count - 7)
        return classTypeFrom(objectTypeName) as? MagicsModel.Type
    }
}

extension String{
    func mgcs_index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func mgcs_substring(from: Int) -> String {
        let fromIndex = mgcs_index(from: from)
        return substring(from: fromIndex)
    }

    func mgcs_substring(from: Int, length: Int) -> String {
        let fromIndex = mgcs_index(from: from)
        return substring(from: fromIndex).mgcs_substring(to: length)
    }

    func mgcs_substring(to: Int) -> String {
        let toIndex = mgcs_index(from: to)
        return substring(to: toIndex)
    }
}

func classTypeFrom(_ className: String) -> AnyClass!{
    if  let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
        // generate the full name of your class (take a look into your "YourProject-swift.h" file)
        let classStringName = "_TtC\(appName.characters.count)\(appName)\(className.characters.count)\(className)"
        // return the class!
        return NSClassFromString(classStringName)
    }
    return nil
}
