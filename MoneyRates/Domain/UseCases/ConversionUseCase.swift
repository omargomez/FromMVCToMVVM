//
//  Conversion.swift
//  MoneyRates
//
//  Created by Omar Gomez on 4/3/22.
//

import Foundation
import Combine

protocol ConversionUseCase {
    
    typealias CompletionType = (Result<Double, Error>) -> ()
    
    func execute(sourceSymbol: String, targetSymbol: String, amount: Double) -> AnyPublisher <Double, Error>
}

final class ConversionUseCaseImpl: ConversionUseCase {
    
    let exchangeService: ExchangeRateGateWay
    
    init(exchangeService: ExchangeRateGateWay = ExchangeRateGateWayImpl()) {
        self.exchangeService = exchangeService
    }
    
    func execute(sourceSymbol: String, targetSymbol: String, amount: Double) -> AnyPublisher <Double, Error> {
        
        let result: Future<Double, Error> = Future() { promise in
            guard amount >= 0.01 else {
                return promise(.success(0.0))
            }
            
            self.exchangeService.convert(sourceSymbol: sourceSymbol, targetSymbol: targetSymbol, amount: amount, completion: { result in
                switch result {
                case .success(let value):
                    return promise(.success(value))
                case .failure(let error):
                    return promise(.failure(error))
                }
            })
        }
        
        return result.eraseToAnyPublisher()
    }
}
