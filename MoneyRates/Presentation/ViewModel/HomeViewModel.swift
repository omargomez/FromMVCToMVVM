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

struct HomeViewInput {
    let onLoad: AnyPublisher<Void, Never>
    let onInputSource: AnyPublisher<String, Never>
    let onInputTarget: AnyPublisher<String, Never>
    let pickSourceEvent: AnyPublisher<Void, Never>
    let pickTargetEvent: AnyPublisher<Void, Never>
    let onSource: AnyPublisher<SymbolModel, Never>
    let onTarget: AnyPublisher<SymbolModel, Never>
}

struct HomeViewOutput {
    let sourceTitle: AnyPublisher<String?, Never>
    let targetTitle: AnyPublisher<String?, Never>
    let error: AnyPublisher<ErrorViewModel?, Never>
    let sourceResult: AnyPublisher<AmountViewModel?, Never>
    let targetResult: AnyPublisher<AmountViewModel?, Never>
    let busy: AnyPublisher<Bool, Never>
}

protocol HomeViewModel {
    func bind(input: HomeViewInput) -> HomeViewOutput
}

enum HomeViewModelError: LocalizedError {
    case error
    
    var errorDescription: String? {
        "Some error"
    }
}

class HomeViewModelImpl: ObservableObject, HomeViewModel {

    @Published private(set) var sourceTitle: String? = nil
    @Published private(set) var targetTitle: String? = nil
    @Published private(set) var error: ErrorViewModel? = nil
    @Published private(set) var sourceResult: AmountViewModel? = nil
    @Published private(set) var targetResult: AmountViewModel? = nil
    @Published private(set) var busy: Bool = false
    
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

    func bind(input: HomeViewInput) -> HomeViewOutput {
    
        input.pickSourceEvent
            .sink(receiveValue: {
                self.coordinator?.goToPickSource()
            }).store(in: &cancellables)
        
        input.pickTargetEvent
            .sink(receiveValue: {
                self.coordinator?.goToPickTarget()
            })
            .store(in: &cancellables)
        
        input.onSource
            .map({ symbol -> String in
                return symbol.description
            })
            .assign(to: &self.$sourceTitle)
        
        input.onTarget
            .map({ symbol -> String in
                return symbol.description
            })
            .assign(to: &self.$targetTitle)
        
        input.onLoad
            .handleEvents(receiveOutput: { _ in
                self.busy = true
            })
            .map({
                self.resetDataUC.execute()
                    .catch { _ -> Just<Bool> in
                        Just(false)
                    }
            })
            .switchToLatest()
            .sink(receiveValue: { _ in
                self.busy = false
            })
            .store(in: &cancellables)
        
        setup(input: input.onInputSource,
              sourceSymbol: input.onSource,
              targetSymbol: input.onTarget)
            .sink(receiveValue: { result in
                switch result {
                case .success(let amount):
                    self.targetResult = AmountViewModel(value: amount)
                case .failure(let error):
                    self.error = ErrorViewModel(error: error)
                }
            })
        
            .store(in: &cancellables)
        setup(input: input.onInputTarget,
              sourceSymbol: input.onTarget,
              targetSymbol: input.onSource)
            .sink(receiveValue: { result in
                switch result {
                case .success(let amount):
                    self.sourceResult = AmountViewModel(value: amount)
                case .failure(let error):
                    self.error = ErrorViewModel(error: error)
                }
            })
            .store(in: &cancellables)
        
        return HomeViewOutput(sourceTitle: $sourceTitle.eraseToAnyPublisher(),
                                   targetTitle: $targetTitle.eraseToAnyPublisher(),
                                   error: $error.eraseToAnyPublisher(),
                                   sourceResult: $sourceResult.eraseToAnyPublisher(),
                                   targetResult: $targetResult.eraseToAnyPublisher(),
                                   busy: $busy.eraseToAnyPublisher())
        
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
                self.busy = true
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
                self.busy = false
            })
            .eraseToAnyPublisher()
    }
}
