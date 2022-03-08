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
        "\(value)"
    }
}

protocol HomeViewModel {
    
    // Inputs
    func onSource(symbol: SymbolModel)
    func onTarget(symbol: SymbolModel)
    func sourceChanged(input: String)
    func pickSource()
    func pickTarget()
    
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
    
    func onSource(symbol: SymbolModel) {
        sourceSymbol = symbol.id
        _sourceTitle = symbol.description
        tryConversion()
    }
    
    func onTarget(symbol: SymbolModel) {
        targetSymbol = symbol.id
        _targetTitle = symbol.description
        tryConversion()
    }
    
    func sourceChanged(input: String) {
        sourceAmount = (input as NSString).doubleValue
        
        tryConversion()
    }
    
    func pickSource() {
        coordinator?.goToPickSource()
    }
    
    func pickTarget() {
        coordinator?.goToPickTarget()
    }
    
    private func tryConversion() {
        guard let amount = sourceAmount,
                let sourceSymbol = sourceSymbol,
              let targetSymbol = targetSymbol else {
                  
                  print("tryConversion, FAIL")
                  
                  return
              }
        
        lastConvertItem?.cancel()
        
        let newConvertItem = DispatchWorkItem(block: {
            self._busy = true
            self.conversionUC.execute(sourceSymbol: sourceSymbol, targetSymbol: targetSymbol, amount: amount, completion: { [weak self] result in
                guard let self = self else { return }
                self._busy = false
                switch result {
                case .success(let value):
                    self._targetResult = AmountViewModel(value: value)
                case .failure(let error):
                    self._error = ErrorViewModel(error: error)
                }
                
            })
        })
        lastConvertItem = newConvertItem
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.30, execute: newConvertItem)
        
    }

    func bind(onLoad: AnyPublisher<Void, Never>,
              onInputSource: AnyPublisher<String, Never>,
              pickSourceEvent: AnyPublisher<Void, Never>,
              pickTargetEvent: AnyPublisher<Void, Never>,
              onSource: AnyPublisher<SymbolModel, Never>,
              onTarget: AnyPublisher<SymbolModel, Never>
    ) {
        onLoad
            .sink(receiveValue: { _ in
                print("Loading")
                self._busy = true
                self.resetDataUC.execute(completion: { result in
                    self._busy = false
                    switch result {
                    case .failure(let error):
                        self._error = ErrorViewModel(error: error)
                    default:
                        break
                    }
                })
            }).store(in: &cancellables)
        
        onInputSource
            .sink(receiveValue: { input in
                self.sourceAmount = (input as NSString).doubleValue
                self.tryConversion()
            }).store(in: &cancellables)
        
        pickSourceEvent
            .sink(receiveValue: {
                self.coordinator?.goToPickSource()
            }).store(in: &cancellables)
        
        pickTargetEvent
            .sink(receiveValue: {
                self.coordinator?.goToPickTarget()
            }).store(in: &cancellables)
        
        onSource
            .sink(receiveValue: { symbol in
                self.sourceSymbol = symbol.id
                self._sourceTitle = symbol.description
                self.tryConversion()
            }).store(in: &cancellables)
        
        onTarget
            .sink(receiveValue: { symbol in
                self.targetSymbol = symbol.id
                self._targetTitle = symbol.description
                self.tryConversion()
            }).store(in: &cancellables)
    }
}

    
