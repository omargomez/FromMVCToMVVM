//
//  ExchangeRateGateWayImpl.swift
//  MoneyRates
//
//  Created by Omar Gomez on 5/3/22.
//

import Foundation

final class ExchangeRateGateWayImpl:ExchangeRateGateWay {
    
    private let service: ExchangeRateService
    
    init(service: ExchangeRateService = ExchangeRateServiceImpl()) {
        self.service = service
    }
    
    func symbols(completion: @escaping (Result<[SymbolModel], Error>) -> Void) {
        service.symbols(completion: { result in
            switch result {
            case .success(let apiSymbols):
                completion(.success(apiSymbols.map({ SymbolModel(id: $0.code, description: $0.descripton) })))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
    func convert(sourceSymbol: String, targetSymbol: String, amount: Double, completion: @escaping (Result<Double, Error>) -> Void) {
        service.convert(sourceSymbol: sourceSymbol, targetSymbol: targetSymbol, amount: amount, completion: { result in
            completion(result)
        })
    }
    
}
