//
//  PickCurrencyViewModel.swift
//  MoneyRates
//
//  Created by Omar Gomez on 3/3/22.
//

import Foundation

struct ErrorViewModel {
    let title: String
    let description: String
}

extension ErrorViewModel {
    
    init(error: Error) {
        self.init(title: "An Error Occurred", description: error.localizedDescription)
    }
    
}

protocol PickCurrencyViewModelDelegate: AnyObject {
    func onSymbolSelected(viewModel: PickCurrencyViewModel, symbol: SymbolModel)
}

enum PickCurrencyModeEnum {
    case source
    case target
}

protocol PickCurrencyViewModel {
    
    var mode: PickCurrencyModeEnum { get set }
    var loaded: Box<Bool> { get }
    var error: Box<Error?> { get }
    var symbols: Box<[SymbolModel]> { get }
    var delegate: PickCurrencyViewModelDelegate? { get set }
    
    func onLoad()
    func currencyCount() -> Int
    func onSelection(row: Int)
}

final class PickCurrencyViewModelImpl: PickCurrencyViewModel {
    
    var loaded: Box<Bool> = Box(false)
    var error: Box<Error?> = Box(nil)
    var symbols: Box<[SymbolModel]> = Box([])
    var mode: PickCurrencyModeEnum = .source
    weak var delegate: PickCurrencyViewModelDelegate?
    
    let userCase: SymbolUseCase
    
    init(useCase: SymbolUseCase = SymbolUseCaseImpl() ) {
        self.userCase = useCase
    }
    
    func onLoad() {
        userCase.getSymbols(completion: { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let symbols):
                print("symbols.bind OK: \(symbols.count)")
                self.symbols.value = symbols
            case .failure(let error):
                self.error.value = error
            }
        })
    }

    func currencyCount() -> Int {
        print("currencyCount(): \(symbols.value.count)")
        return symbols.value.count
    }

    func onSelection(row: Int) {
        let symbol = self.symbols.value[row]
        delegate?.onSymbolSelected(viewModel: self, symbol: symbol)
    }
}
