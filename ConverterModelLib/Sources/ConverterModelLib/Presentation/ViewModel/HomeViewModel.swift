//
//  HomeViewModel.swift
//  MoneyRates
//
//  Created by Omar Gomez on 21/2/22.
//

import Foundation

public struct AmountViewModel: CustomStringConvertible {
    
    public let value: Double
    
    public var description: String {
        String(format: "%.2f", value)
    }
}

public protocol HomeViewModel {
    
    var symbols: Box<[SymbolModel]> { get }
    var sourceTitle: Box<String?> { get }
    var targetTitle: Box<String?> { get }
    var error: Box<ErrorViewModel?> {get}
    var targetResult: Box<AmountViewModel?> { get }
    var sourceResult: Box<AmountViewModel?> { get }
    var busy: Box<Bool> { get }
    func onLoadView()
    func onSource(symbol: SymbolModel)
    func onTarget(symbol: SymbolModel)
    func sourceChanged(input: String)
    func targetChanged(input: String)
    func pickSource()
    func pickTarget()
}


public class HomeViewModelImpl: HomeViewModel {
    
    public let symbols = Box<[SymbolModel]>([])
    public let error = Box<ErrorViewModel?>(nil)
    public let sourceTitle = Box<String?>(nil)
    public let targetTitle = Box<String?>(nil)
    public var targetResult: Box<AmountViewModel?> = Box(nil)
    public var sourceResult: Box<AmountViewModel?> = Box(nil)
    public var busy: Box<Bool> = Box(true)
    
    private var sourceSymbol: String?
    private var targetSymbol: String?
    private var sourceAmount: Double?
    private var targetAmount: Double?
    
    public var coordinator: HomeCoordinator? = nil
    let conversionUC: ConversionUseCase
    let resetDataUC: ResetDataUsecase
    
    var lastConvertItem: DispatchWorkItem? = nil
    
    public init() {
        self.conversionUC = ConversionUseCaseImpl()
        self.resetDataUC = ResetDataUseCaseImpl()
    }
    
    init(symbolRepository: SymbolRepository = SymbolRepositoryImpl(), exchangeService: ExchangeRateService = ExchangeRateServiceImpl(),
         conversionUC: ConversionUseCase = ConversionUseCaseImpl(),
         resetDataUC: ResetDataUsecase = ResetDataUseCaseImpl()) {
        self.conversionUC = conversionUC
        self.resetDataUC = resetDataUC
    }
    
    public func onLoadView() {
        print("Loading")
        self.busy.value = true
        self.resetDataUC.execute(completion: { result in
            self.busy.value = false
            switch result {
            case .failure(let error):
                self.error.value = ErrorViewModel(error: error)
            default:
                break
            }
        })
    }
    
    public func onSource(symbol: SymbolModel) {
        sourceSymbol = symbol.id
        sourceTitle.value = symbol.description
        tryConversion()
    }
    
    public func onTarget(symbol: SymbolModel) {
        targetSymbol = symbol.id
        targetTitle.value = symbol.description
        tryConversion()
    }
    
    public func sourceChanged(input: String) {
        sourceAmount = (input as NSString).doubleValue
        
        tryConversion()
    }
    
    public func targetChanged(input: String) {
        sourceAmount = (input as NSString).doubleValue
        
        tryConversion(inverted: true)
    }
    
    public func pickSource() {
        coordinator?.goToPickSource()
    }
    
    public func pickTarget() {
        coordinator?.goToPickTarget()
    }
    
    private func tryConversion(inverted: Bool = false) {
        guard let amount = sourceAmount,
              let actualSourceSymbol = (inverted ? targetSymbol : sourceSymbol),
              let actualTargetSymbol = (inverted ? sourceSymbol : targetSymbol) else {
                  
                  print("tryConversion, FAIL")
                  
                  return
              }
        
        lastConvertItem?.cancel()
        
        let newConvertItem = DispatchWorkItem(block: {
            self.busy.value = true
            self.conversionUC.execute(sourceSymbol: actualSourceSymbol, targetSymbol: actualTargetSymbol, amount: amount, completion: { [weak self] result in
                guard let self = self else { return }
                self.busy.value = false
                switch result {
                case .success(let value):
                    if inverted {
                        self.sourceResult.value = AmountViewModel(value: value)
                    } else {
                        self.targetResult.value = AmountViewModel(value: value)
                    }
                case .failure(let error):
                    self.error.value = ErrorViewModel(error: error)
                }
                
            })
        })
        lastConvertItem = newConvertItem
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.30, execute: newConvertItem)
        
    }
}

    
