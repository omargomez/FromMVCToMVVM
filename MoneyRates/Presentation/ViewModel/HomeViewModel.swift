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
    let onLoad = PassthroughSubject<Void, Never>()
    let onInputSource = PassthroughSubject<String, Never>()
    let onInputTarget = PassthroughSubject<String, Never>()
    let pickSourceEvent = PassthroughSubject<Void, Never>()
    let pickTargetEvent = PassthroughSubject<Void, Never>()
    let onSource = PassthroughSubject<SymbolModel, Never>()
    let onTarget = PassthroughSubject<SymbolModel, Never>()
}

struct HomeViewOutput {
    let sourceTitle: AnyPublisher<String?, Never>
    let targetTitle: AnyPublisher<String?, Never>
    let error: AnyPublisher<ErrorViewModel?, Never>
    let sourceResult: AnyPublisher<AmountViewModel?, Never>
    let targetResult: AnyPublisher<AmountViewModel?, Never>
    let busy: AnyPublisher<Bool, Never>
}

protocol HomeViewModel: AnyObject {
        
    // Input methods
    func onLoad()
    func onInput(source: String)
    func onInput(target: String)
    func pickSourceEvent()
    func pickTargetEvent()
    func onSelection(source: SymbolModel)
    func onSelection(target: SymbolModel)
    
    // Output properties
    var sourceTitle: String? { get }
    var targetTitle: String? { get }
    var error: ErrorViewModel? { get }
    var sourceResult: AmountViewModel? { get }
    var targetResult: AmountViewModel? { get }
    var busy: Bool { get }
    
    func output() -> HomeViewOutput
}

enum HomeViewModelError: LocalizedError {
    case error
    
    var errorDescription: String? {
        "Some error"
    }
}

class HomeViewModelImpl: HomeViewModel {
    func onLoad() {
        input.onLoad.send( () )
    }
    
    func onInput(source: String) {
        input.onInputSource.send(source)
    }
    
    func onInput(target: String) {
        input.onInputTarget.send(target)
    }
    
    func pickSourceEvent() {
        input.pickSourceEvent.send(())
    }
    
    func pickTargetEvent() {
        input.pickTargetEvent.send(())
    }
    
    func onSelection(source: SymbolModel) {
        input.onSource.send(source)
    }
    
    func onSelection(target: SymbolModel) {
        input.onTarget.send(target)
    }
    
    @Published var sourceTitle: String? = nil
    @Published var targetTitle: String? = nil
    @Published var error: ErrorViewModel? = nil
    @Published var sourceResult: AmountViewModel? = nil
    @Published var targetResult: AmountViewModel? = nil
    @Published var busy: Bool = false
    
    private let input = HomeViewInput()
    
    var coordinator: HomeCoordinator? = nil
    let conversionUC: ConversionUseCase
    let resetDataUC: ResetDataUsecase
    
    private var cancellables: Set<AnyCancellable> = []
    typealias ConversionType = Result<Double, Error>
    
    init(symbolRepository: SymbolRepository = SymbolRepositoryImpl(), exchangeService: ExchangeRateService = ExchangeRateServiceImpl(),
         conversionUC: ConversionUseCase = ConversionUseCaseImpl(),
         resetDataUC: ResetDataUsecase = ResetDataUseCaseImpl()) {
        self.conversionUC = conversionUC
        self.resetDataUC = resetDataUC
        
        setup()
    }

    func setup() {
    
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
        
    }
    
    func output() -> HomeViewOutput {
        return HomeViewOutput(sourceTitle: $sourceTitle.eraseToAnyPublisher(),
                                   targetTitle: $targetTitle.eraseToAnyPublisher(),
                                   error: $error.eraseToAnyPublisher(),
                                   sourceResult: $sourceResult.eraseToAnyPublisher(),
                                   targetResult: $targetResult.eraseToAnyPublisher(),
                                   busy: $busy.eraseToAnyPublisher())
    }
}

private extension HomeViewModelImpl {
    func setup(input: PassthroughSubject<String, Never>,
               sourceSymbol: PassthroughSubject<SymbolModel, Never>,
               targetSymbol: PassthroughSubject<SymbolModel, Never>
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
