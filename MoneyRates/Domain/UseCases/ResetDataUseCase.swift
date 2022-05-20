//
//  ResetDataUseCase.swift
//  MoneyRates
//
//  Created by Omar Gomez on 4/3/22.
//

import Foundation
import Combine

protocol ResetDataUsecase {
    
    typealias CompletionType = (Result<Void, Error>) -> ()
    
    func execute(completion: @escaping CompletionType)
    func execute() -> AnyPublisher<Bool, Error>
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
    
    func execute() -> AnyPublisher<Bool, Error> {
        let result: Future<Bool, Error> = Future() { promise in
            self.exchangeService.symbols(completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let symbolArray):
                    self.symbolRepository.reset(items: symbolArray, completion: { _ in
                        switch result {
                        case .success:
                            promise(.success(true))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    })
                case .failure(let error):
                    promise(.failure(error))
                }
            })
        }
        return result.eraseToAnyPublisher()
        
    }
}
