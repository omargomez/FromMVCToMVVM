//
//  SymbolRepositoryGatewayImpl.swift
//  MoneyRates
//
//  Created by Omar Gomez on 5/3/22.
//

import Foundation

final class SymbolRepositoryGatewayImpl: SymbolRepositoryGateway {
    
    private let repository: SymbolRepository
    
    init(repository: SymbolRepository = SymbolRepositoryImpl()) {
        self.repository = repository
    }
    
    func reset(items: [SymbolModel], completion: @escaping (Result<Void, Error>) -> Void) {
        repository.reset(apiItems: items.map({APISymbolsItem(code: $0.id, descripton: $0.description)}), completion: { result in
            completion(result)
        })
    }
    
    func getAll() -> [SymbolModel]? {
        repository.getAll()?.compactMap({ toModel($0) })
    }
    
    func getSymbol(code: String) -> SymbolModel? {
        guard let symbol = repository.getSymbol(code: code) else {
            return nil
        }
        return toModel(symbol)
    }
    
    func count() throws -> Int {
        try repository.count()
    }
    
    private func toModel(_ entity: SymbolEntity) -> SymbolModel? {
        guard let code = entity.code,
              let description = entity.symbolDescription else {
                  return nil
              }
        return SymbolModel(id: code, description: description)
    }
    
}
