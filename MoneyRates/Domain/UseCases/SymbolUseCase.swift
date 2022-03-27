//
//  SymbolUseCase.swift
//  MoneyRates
//
//  Created by Omar Gomez on 3/3/22.
//

import Foundation

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
    
    func getSymbols(completion: @escaping CompletionType)
    func filterSymbols(text: String?) -> [SymbolModel]?
}

class SymbolUseCaseImpl: SymbolUseCase {
    
    private let symbolRepository: SymbolRepositoryGateway
    private let exchangeService: ExchangeRateGateWay
    
    init(symbolRepository: SymbolRepositoryGateway = SymbolRepositoryGatewayImpl(), exchangeService: ExchangeRateGateWay = ExchangeRateGateWayImpl()) {
        self.symbolRepository = symbolRepository
        self.exchangeService = exchangeService
    }
    
    func getSymbols(completion: @escaping CompletionType) {
        guard let count = try? symbolRepository.count(),
              count > 0 else {
                  self.exchangeService.symbols(completion: { [weak self] result in
                      guard let self = self else { return }
                      switch result {
                      case .success(let symbolArray):
                          print("symbols: \(symbolArray.count)")
                          self.symbolRepository.reset(items: symbolArray, completion: { [weak self] result in
                              guard let self = self else { return }
                              switch result {
                              case .success:
                                  print("reset OK")
                                  completion(.success(self.symbolRepository.getAll() ?? []))
                                  
                              case .failure(let error):
                                  print("reset FAIL")
                                  completion(.failure(error))
                              }
                          })
                      case .failure(let error):
                          print("symbols FAIL \(error.localizedDescription)")
                          completion(.failure(error))
                      }
                  })
                  return
              }
        
        print("count OK \(count)")
        completion(.success(self.symbolRepository.getAll() ?? []))
        
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
