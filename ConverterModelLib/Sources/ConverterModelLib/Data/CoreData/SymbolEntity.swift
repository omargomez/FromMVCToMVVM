//
//  File.swift
//  
//
//  Created by Omar Eduardo Gomez Padilla on 4/07/22.
//

import Foundation
import CoreData

@objc(SymbolEntity)

final public class SymbolEntity: NSManagedObject {
    
    @NSManaged var code: String?
    @NSManaged var symbolDescription: String?
}
