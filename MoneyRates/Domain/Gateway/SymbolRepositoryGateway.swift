//
//  SymbolRepositoryGateway.swift
//  MoneyRates
//
//  Created by Omar Gomez on 5/3/22.
//

import Foundation

protocol SymbolRepositoryGateway {
    
    func reset(items: [SymbolModel], completion: @escaping (Result<Void, Error>) -> Void )
    func getAll() -> [SymbolModel]?
    func getSymbol(code: String) -> SymbolModel?
    func count() throws -> Int
    func filter(text: String) -> [SymbolModel]?

}
