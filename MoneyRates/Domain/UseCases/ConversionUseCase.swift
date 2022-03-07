//
//  Conversion.swift
//  MoneyRates
//
//  Created by Omar Gomez on 4/3/22.
//

import Foundation

protocol ConversionUseCase {
    
    typealias CompletionType = (Result<Double, Error>) -> ()
    
    func execute(sourceSymbol: String, targetSymbol: String, amount: Double, completion: @escaping CompletionType )
}

final class ConversionUseCaseImpl: ConversionUseCase {
    
    let exchangeService: ExchangeRateGateWay
    
    init(exchangeService: ExchangeRateGateWay = ExchangeRateGateWayImpl()) {
        self.exchangeService = exchangeService
    }
    
    func execute(sourceSymbol: String, targetSymbol: String, amount: Double, completion: @escaping CompletionType) {
        
        guard amount >= 0.01 else {
            completion(.success(0.0))
            return
        }
        
        self.exchangeService.convert(sourceSymbol: sourceSymbol, targetSymbol: targetSymbol, amount: amount, completion: { result in
            completion(result)
        })
    }
}
