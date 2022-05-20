//
//  HomeViewModel.swift
//  MoneyRates
//
//  Created by Omar Gomez on 21/2/22.
//

import Foundation
import Combine

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
              onInputTarget: AnyPublisher<String, Never>,
              pickSourceEvent: AnyPublisher<Void, Never>,
              pickTargetEvent: AnyPublisher<Void, Never>,
              onSource: AnyPublisher<SymbolModel, Never>,
              onTarget: AnyPublisher<SymbolModel, Never>
    )
    
    // Output
    var sourceTitle: AnyPublisher<String?, Never> { get }
    var targetTitle: AnyPublisher<String?, Never> { get }
    var error: AnyPublisher<ErrorViewModel?, Never> { get }
    var sourceResult: AnyPublisher<AmountViewModel?, Never> { get }
    var targetResult: AnyPublisher<AmountViewModel?, Never> { get }
    var busy: AnyPublisher<Bool, Never> { get }
    
}

enum HomeViewModelError: LocalizedError {
    case error
    
    var errorDescription: String? {
        "Some error"
    }
}

class HomeViewModelImpl: ObservableObject, HomeViewModel {
    var sourceTitle: AnyPublisher<String?, Never> { $_sourceTitle.eraseToAnyPublisher() }
    var targetTitle: AnyPublisher<String?, Never> { $_targetTitle.eraseToAnyPublisher() }
    var error: AnyPublisher<ErrorViewModel?, Never> { $_error.eraseToAnyPublisher() }
    var sourceResult: AnyPublisher<AmountViewModel?, Never> { $_sourceResult.eraseToAnyPublisher() }
    var targetResult: AnyPublisher<AmountViewModel?, Never> { $_targetResult.eraseToAnyPublisher() }
    var busy: AnyPublisher<Bool, Never> { $_busy.eraseToAnyPublisher() }
    
    @Published private(set) var _sourceTitle: String? = nil
    @Published private(set) var _targetTitle: String? = nil
    @Published private(set) var _error: ErrorViewModel? = nil
    @Published private(set) var _sourceResult: AmountViewModel? = nil
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
    typealias ConversionType = Result<Double, Error>
    
    init(symbolRepository: SymbolRepository = SymbolRepositoryImpl(), exchangeService: ExchangeRateService = ExchangeRateServiceImpl(),
         conversionUC: ConversionUseCase = ConversionUseCaseImpl(),
         resetDataUC: ResetDataUsecase = ResetDataUseCaseImpl()) {
        self.conversionUC = conversionUC
        self.resetDataUC = resetDataUC
    }
    
    func bind(onLoad: AnyPublisher<Void, Never>,
              onInputSource: AnyPublisher<String, Never>,
              onInputTarget: AnyPublisher<String, Never>,
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
        
            setup(input: onInputSource,
                sourceSymbol: onSource,
                targetSymbol: onTarget)
            .sink(receiveValue: { result in
                switch result {
                case .success(let amount):
                    self._targetResult = AmountViewModel(value: amount)
                case .failure(let error):
                    self._error = ErrorViewModel(error: error)
                }
            })
        
            .store(in: &cancellables)
            setup(input: onInputTarget,
                sourceSymbol: onTarget,
                targetSymbol: onSource)
            .sink(receiveValue: { result in
                switch result {
                case .success(let amount):
                    self._sourceResult = AmountViewModel(value: amount)
                case .failure(let error):
                    self._error = ErrorViewModel(error: error)
                }
            })
            .store(in: &cancellables)
    }
}

private extension HomeViewModelImpl {
    func setup(input: AnyPublisher<String, Never>,
               sourceSymbol: AnyPublisher<SymbolModel, Never>,
               targetSymbol: AnyPublisher<SymbolModel, Never>
    ) -> AnyPublisher<ConversionType, Never> {
        input
            .compactMap({ text -> Double? in
                guard let val = Double(text),
                      val >= 0.01 else {
                          return nil
                      }
                return val
            })
            .combineLatest(sourceSymbol, targetSymbol)
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
            .eraseToAnyPublisher()
    }
}
