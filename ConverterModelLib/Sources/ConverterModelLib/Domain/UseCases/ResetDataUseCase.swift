//
//  ResetDataUseCase.swift
//  MoneyRates
//
//  Created by Omar Gomez on 4/3/22.
//

import Foundation

protocol ResetDataUsecase {
    
    typealias CompletionType = (Result<Void, Error>) -> ()
    
    func execute(completion: @escaping CompletionType)
}

final class ResetDataUseCaseImpl: ResetDataUsecase {
    
    let symbolRepository: SymbolRepositoryGateway
    let exchangeService: ExchangeRateGateWay
    
    init(symbolRepository: SymbolRepositoryGateway = SymbolRepositoryGatewayImpl(), exchangeService: ExchangeRateGateWay = ExchangeRateGateWayImpl()) {
        self.symbolRepository = symbolRepository
        self.exchangeService = exchangeService
    }
    
    func execute(completion: @escaping CompletionType) {
        self.exchangeService.symbols(completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let symbolArray):
                self.symbolRepository.reset(items: symbolArray, completion: { _ in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
