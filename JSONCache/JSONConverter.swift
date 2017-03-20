//
//  JSONConverter.swift
//  JSONCache
//
//  Created by Anders Blehr on 09/03/2017.
//  Copyright © 2017 Anders Blehr. All rights reserved.
//

import Foundation


public struct JSONConverter {
    
    public enum Direction {
        case fromJSON
        case toJSON
    }
    
    
    public static func convert(_ direction: Direction, dictionary: [String: Any], qualifier: String? = nil) -> [String: Any] {
        
        if JSONCache.casing == .camelCase {
            return dictionary
        }
        
        var convertedDictionary = [String: Any]()
        for (key, value) in dictionary {
            convertedDictionary[convert(direction, string: key, qualifier: qualifier)] = value
        }
        
        return convertedDictionary
    }
    
    
    public static func convert(_ direction: Direction, string: String, qualifier: String? = nil) -> String {
        
        if JSONCache.casing == .camelCase {
            return string
        }
        
        switch direction {
        case .fromJSON:
            if string.contains("_") {
                var convertedString = ""
                let components = string.components(separatedBy: "_")
                for (i, component) in components.enumerated() {
                    convertedString += i == 0 ? component : component.capitalized
                }
                
                return convertedString
            } else if string == "description" && qualifier != nil {
                var qualifier = qualifier!
                return String(qualifier.remove(at: qualifier.startIndex)).lowercased() + qualifier + "Description"
            } else {
                return string
            }
        case .toJSON:
            let convertedString = string.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1_$2", options: .regularExpression).lowercased()
            
            return convertedString.hasSuffix("_description") ? "description" : convertedString
        }
    }
}
