//
//  MagicsJSON.swift
//  Magics
//
//  Created by Nikita Arkhipov on 25.08.17.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation

public class MagicsJSON{
    public var isArray: Bool { return data is NSArray }
    public var isDictionary: Bool { return data is NSDictionary }
    
    public var array: NSArray? { return data as? NSArray }
    public var dictionary: NSDictionary? { return data as? NSDictionary }
    
    public var int: Int! { return data as? Int }
    public var string: String! { return (data as? String) ?? ((int != nil ? "\(int!)" : nil) ?? (double != nil ? "\(double!)" : nil)) }
    
    public var double: Double! { return data as? Double }
    public var bool: Bool! { return data as? Bool }
    
    public var numberOfItems: Int{ return array?.count ?? dictionary?.count ?? 1 }
    
    public let data: Any
    
    public init(data: Any){
        self.data = data
    }
    
    public subscript(index: Int) -> MagicsJSON!{
        if let array = array, index < array.count { return MagicsJSON(data: array[index]) }
        if let dictionary = dictionary,
            let value = dictionary[index] { return MagicsJSON(data: value) }
        return nil
    }
    
    public subscript(key: String) -> MagicsJSON!{
        guard let dict = dictionary, let data = dict[key] else { return nil }
        return MagicsJSON(data: data)
    }
    
    public func jsonAt(path: String) -> MagicsJSON?{
        func jsonFrom(json: MagicsJSON, array: [String]) -> MagicsJSON?{
            var ma = array
            guard let json2 = json[ma.remove(at: 0)] else { return nil }
            if ma.count == 0 { return json2 }
            return jsonFrom(json: json2, array: ma)
            
        }
        let options = path.components(separatedBy: "/")
        for o in options{
            if let js = jsonFrom(json: self, array: o.components(separatedBy: ".")) {
                return js
            }
        }
        return nil
    }
    
    
    public func toString(_ v: Any) -> String?{
        return (v as? String) ?? String(describing: v)
    }
    
    public func enumerate(_ callback: (String?, MagicsJSON) -> Void){
        if let dict = dictionary{
            for key in dict.allKeys{
                callback(toString(key), MagicsJSON(data: dict[key] as Any))
            }
        }
        if let array = array{
            for el in array{
                callback(nil, MagicsJSON(data: el))
            }
        }
    }
    
    public static func loadWith(request: URLRequest, completion: @escaping (MagicsJSON?, URLResponse?, Error?) -> Void){
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, response, error)
                return
            }
            if let dataResponse = data,
                let json = try? JSONSerialization.jsonObject(with: dataResponse, options: .allowFragments) as AnyObject{
                completion(MagicsJSON(data: json), response, nil)
                return
            }

            if let response = response as? HTTPURLResponse, response.statusCode != 200{
                completion(nil, response, NSError(domain: "ru.Magics.InvalidStatusCode", code: 2, userInfo: ["statusCode": response.statusCode]))
                return
            }
            completion(nil, response, nil)
        }
        task.resume()
    }
}

extension MagicsJSON: CustomStringConvertible{
    public var description: String { return "\(data)" }
}
