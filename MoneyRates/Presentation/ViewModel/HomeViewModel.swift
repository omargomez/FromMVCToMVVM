//
//  HomeViewModel.swift
//  MoneyRates
//
//  Created by Omar Gomez on 21/2/22.
//

import Foundation

struct AmountViewModel: CustomStringConvertible {
    
    let value: Double
    
    var description: String {
        String(format: "%.2f", value)
    }
}

protocol HomeViewModel {
    
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


class HomeViewModelImpl: HomeViewModel {
    
    let symbols = Box<[SymbolModel]>([])
    let error = Box<ErrorViewModel?>(nil)
    let sourceTitle = Box<String?>(nil)
    let targetTitle = Box<String?>(nil)
    var targetResult: Box<AmountViewModel?> = Box(nil)
    var sourceResult: Box<AmountViewModel?> = Box(nil)
    var busy: Box<Bool> = Box(true)
    
    private var sourceSymbol: String?
    private var targetSymbol: String?
    private var sourceAmount: Double?
    private var targetAmount: Double?
    
    var coordinator: HomeCoordinator? = nil
    let conversionUC: ConversionUseCase
    let resetDataUC: ResetDataUsecase
    
    var lastConvertItem: DispatchWorkItem? = nil
    
    init(symbolRepository: SymbolRepository = SymbolRepositoryImpl(), exchangeService: ExchangeRateService = ExchangeRateServiceImpl(),
         conversionUC: ConversionUseCase = ConversionUseCaseImpl(),
         resetDataUC: ResetDataUsecase = ResetDataUseCaseImpl()) {
        self.conversionUC = conversionUC
        self.resetDataUC = resetDataUC
    }
    
    func onLoadView() {
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
    
    func onSource(symbol: SymbolModel) {
        sourceSymbol = symbol.id
        sourceTitle.value = symbol.description
        tryConversion()
    }
    
    func onTarget(symbol: SymbolModel) {
        targetSymbol = symbol.id
        targetTitle.value = symbol.description
        tryConversion()
    }
    
    func sourceChanged(input: String) {
        sourceAmount = (input as NSString).doubleValue
        
        tryConversion()
    }
    
    func targetChanged(input: String) {
        sourceAmount = (input as NSString).doubleValue
        
        tryConversion(inverted: true)
    }
    
    func pickSource() {
        coordinator?.goToPickSource()
    }
    
    func pickTarget() {
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

    
