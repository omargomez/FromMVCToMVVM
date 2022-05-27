//
//  SymbolUseCase.swift
//  MoneyRates
//
//  Created by Omar Gomez on 3/3/22.
//

import Foundation
import Combine

enum SymbolUseCaseError: LocalizedError {
    case emptyStore
    
    var errorDescription: String? {
        switch self {
        case .emptyStore:
            return "emptyStore"
        }
    }
    
}

protocol SymbolUseCase {
    
    typealias CompletionType = (Result<[SymbolModel], Error>) -> ()
    
    func symbols() -> AnyPublisher<[SymbolModel], Error>
    func filterSymbols(text: String?) -> [SymbolModel]?
}

class SymbolUseCaseImpl: SymbolUseCase {
    
    private let symbolRepository: SymbolRepositoryGateway
    private let exchangeService: ExchangeRateGateWay
    
    init(symbolRepository: SymbolRepositoryGateway = SymbolRepositoryGatewayImpl(), exchangeService: ExchangeRateGateWay = ExchangeRateGateWayImpl()) {
        self.symbolRepository = symbolRepository
        self.exchangeService = exchangeService
    }
    
    func symbols() -> AnyPublisher<[SymbolModel], Error> {
        let result: Future<[SymbolModel], Error> = Future() { promise in
            guard let count = try? self.symbolRepository.count(),
                  count > 0 else {
                self.exchangeService.symbols(completion: { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let symbolArray):
                        self.symbolRepository.reset(items: symbolArray, completion: { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .success:
                                return promise(.success(self.symbolRepository.getAll() ?? []))
                                
                            case .failure(let error):
                                return promise(.failure(error))
                            }
                        })
                    case .failure(let error):
                        return promise(.failure(error))
                    }
                })
                return
            }
            return promise(.success(self.symbolRepository.getAll() ?? []))
        }
        return result.eraseToAnyPublisher()
    }
    
    func filterSymbols(text: String?) -> [SymbolModel]? {
        guard let text = text else {
            return symbolRepository.getAll()
        }
        
        guard let count = try? symbolRepository.count(),
              count > 0 else {
            return nil
        }
        
        return symbolRepository.filter(text: text)
    }
}
