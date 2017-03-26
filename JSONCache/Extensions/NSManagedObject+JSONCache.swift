//
//  NSManagedObject+JSONCache.swift
//  JSONCache
//
//  Created by Anders Blehr on 10/03/2017.
//  Copyright © 2017 Anders Blehr. All rights reserved.
//

import CoreData
import Foundation


extension NSManagedObject: JSONifiable {
    
    /// The identifier (primary key) value of this object.
    public var identifier: AnyHashable? {
        
        if let identifierName = self.entity.identifierName {
            return self.value(forKey: identifierName) as? AnyHashable
        }
        
        return nil
    }
    
    
    /// Set the attributes of this object from the (key, value) pairs in the
    /// dictionary. Dictionary keys that do not correspond with an attribute name
    /// are ignored.
    ///
    /// - Parameters:
    ///   - dictionary: The dictionary from which to retrieve attribute values.
    
    public func setAttributes(fromDictionary dictionary: [String: Any]) {
        
        for (attributeName, attribute) in self.entity.attributesByName {
            if let value = dictionary[attributeName] {
                if attribute.attributeType == .dateAttributeType {
                    self.setValue(Date(fromJSONValue: value), forKey: attributeName)
                } else {
                    self.setValue(value, forKey: attributeName)
                }
            }
        }
    }
    
    
    // MARK: - JSONifiable conformance
    
    /// Produce a JSON serializable dictionary that represents this object.
    ///
    /// - Returns: A JSON serializable dictionary representing this object.
    
    public func toJSONDictionary() -> [String: Any] {
        
        var dictionary = [String: Any]()
        
        for (attributeName, attribute) in self.entity.attributesByName {
            if let value = self.value(forKey: attributeName) {
                if attribute.attributeType == .dateAttributeType {
                    dictionary[attributeName] = (value as! Date).toJSONValue()
                } else {
                    dictionary[attributeName] = value
                }
            }
        }
        
        for (relationshipName, relationship) in self.entity.relationshipsByName {
            if !relationship.isToMany {
                if let destinationObject = self.value(forKey: relationshipName) as? NSManagedObject {
                    if destinationObject.entity.attributesByName.keys.contains("id") {
                        dictionary[relationshipName] = destinationObject.value(forKey: "id")
                    } else {
                        for (destinationAttributeName, destinationAttribute) in destinationObject.entity.attributesByName {
                            if destinationAttribute.isIdentifier {
                                dictionary[relationshipName] = destinationObject.value(forKey: destinationAttributeName)
                            }
                        }
                    }
                }
            }
        }
        
        return JSONConverter.convert(.toJSON, dictionary: dictionary, qualifier: self.entity.name)
    }
}
