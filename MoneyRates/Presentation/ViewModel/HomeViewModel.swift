//
//  HomeViewModel.swift
//  MoneyRates
//
//  Created by Omar Gomez on 21/2/22.
//

import Foundation
import Combine
import UIKit

struct AmountViewModel: CustomStringConvertible {
    
    let value: Double
    
    var description: String {
        String(format: "%.2f", value)
    }
}

protocol HomeViewModel {
    
    // Inputs
    func bind(onLoad: AnyPublisher<Void, Never>,
              onInputSource: AnyPublisher<String, Never>,
              pickSourceEvent: AnyPublisher<Void, Never>,
              pickTargetEvent: AnyPublisher<Void, Never>,
              onSource: AnyPublisher<SymbolModel, Never>,
              onTarget: AnyPublisher<SymbolModel, Never>
    )
    
    // Output
    var sourceTitle: Published<String?>.Publisher { get }
    var targetTitle: Published<String?>.Publisher { get }
    var error: Published<ErrorViewModel?>.Publisher { get }
    var targetResult: Published<AmountViewModel?>.Publisher { get }
    var busy: Published<Bool>.Publisher { get }
    
}

enum HomeViewModelError: LocalizedError {
    case error
    
    var errorDescription: String? {
        "Some error"
    }
}

class HomeViewModelImpl: ObservableObject, HomeViewModel {
    var sourceTitle: Published<String?>.Publisher { $_sourceTitle }
    var targetTitle: Published<String?>.Publisher { $_targetTitle }
    var error: Published<ErrorViewModel?>.Publisher { $_error }
    var targetResult: Published<AmountViewModel?>.Publisher { $_targetResult }
    var busy: Published<Bool>.Publisher { $_busy }
    
    @Published private(set) var _sourceTitle: String? = nil
    @Published private(set) var _targetTitle: String? = nil
    @Published private(set) var _error: ErrorViewModel? = nil
    @Published private(set) var _targetResult: AmountViewModel? = nil
    @Published private(set) var _busy: Bool = false
    
    private var sourceSymbol: String?
    private var targetSymbol: String?
    private var sourceAmount: Double?
    private var targetAmount: Double?
    
    var coordinator: HomeCoordinator? = nil
    let conversionUC: ConversionUseCase
    let resetDataUC: ResetDataUsecase
    
    var lastConvertItem: DispatchWorkItem? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(symbolRepository: SymbolRepository = SymbolRepositoryImpl(), exchangeService: ExchangeRateService = ExchangeRateServiceImpl(),
         conversionUC: ConversionUseCase = ConversionUseCaseImpl(),
         resetDataUC: ResetDataUsecase = ResetDataUseCaseImpl()) {
        self.conversionUC = conversionUC
        self.resetDataUC = resetDataUC
    }
    
    func bind(onLoad: AnyPublisher<Void, Never>,
              onInputSource: AnyPublisher<String, Never>,
              pickSourceEvent: AnyPublisher<Void, Never>,
              pickTargetEvent: AnyPublisher<Void, Never>,
              onSource: AnyPublisher<SymbolModel, Never>,
              onTarget: AnyPublisher<SymbolModel, Never>
    ) {
        
        pickSourceEvent
            .sink(receiveValue: {
                self.coordinator?.goToPickSource()
            }).store(in: &cancellables)
        
        pickTargetEvent
            .sink(receiveValue: {
                self.coordinator?.goToPickTarget()
            })
            .store(in: &cancellables)
        
        onSource
            .map({ symbol -> String in
                return symbol.description
            })
            .assign(to: &self.$_sourceTitle)
        
        onTarget
            .map({ symbol -> String in
                return symbol.description
            })
            .assign(to: &self.$_targetTitle)
        
        onLoad
            .handleEvents(receiveOutput: { _ in
                self._busy = true
            })
            .map({
                self.resetDataUC.execute()
                    .catch { _ -> Just<Bool> in
                        Just(false)
                    }
            })
            .switchToLatest()
            .sink(receiveValue: { _ in
                self._busy = false
            })
            .store(in: &cancellables)
        
        typealias ConversionType = Result<Double, Error>
        onInputSource
            .compactMap({ text -> Double? in
                guard let val = Double(text),
                      val >= 0.01 else {
                          return nil
                      }
                return val
            })
            .combineLatest(onSource, onTarget)
            .handleEvents(receiveOutput: { _ in
                self._busy = true
            })
            .map({ (amount, source, target) in
                self.conversionUC.execute(sourceSymbol: source.id, targetSymbol: target.id, amount: amount)
                .map({ val -> ConversionType in
                    return .success(val)
                })
                .catch({ error -> Just<ConversionType> in
                    return Just(.failure(error))
                })
            })
            .switchToLatest()
            .handleEvents(receiveOutput: { _ in
                self._busy = false
            })
            .sink(receiveValue: { value in
                switch value {
                case .success(let amount):
                    self._targetResult = AmountViewModel(value: amount)
                case .failure(let error):
                    self._error = ErrorViewModel(error: error)
                }
            })
            .store(in: &cancellables)
                    
    }
}
