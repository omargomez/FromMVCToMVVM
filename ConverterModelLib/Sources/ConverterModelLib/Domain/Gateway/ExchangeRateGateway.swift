//
//  ExchangeRateGateway.swift
//  MoneyRates
//
//  Created by Omar Gomez on 5/3/22.
//

import Foundation

protocol ExchangeRateGateWay {
    func symbols(completion: @escaping (Result<[SymbolModel], Error>) -> Void)
    func convert(sourceSymbol: String, targetSymbol: String, amount: Double, completion: @escaping (Result<Double, Error>) -> Void)
}
