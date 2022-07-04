//
//  PickCurrencyViewModel.swift
//  MoneyRates
//
//  Created by Omar Gomez on 3/3/22.
//

import Foundation

public struct ErrorViewModel {
    public let title: String
    public let description: String
}

extension ErrorViewModel {
    
    public init(error: Error) {
        self.init(title: "An Error Occurred", description: error.localizedDescription)
    }
    
}

public protocol PickCurrencyViewModelDelegate: AnyObject {
    func onSymbolSelected(viewModel: PickCurrencyViewModel, symbol: SymbolModel)
}

public enum PickCurrencyModeEnum {
    case source
    case target
}

public protocol PickCurrencyViewModel {
    
    var mode: PickCurrencyModeEnum { get set }
    var loaded: Box<Bool> { get }
    var error: Box<Error?> { get }
    var symbols: Box<[SymbolModel]> { get }
    var searchEnabled: Box<Bool> { get }
    var delegate: PickCurrencyViewModelDelegate? { get set }
    
    func onLoad()
    func currencyCount() -> Int
    func onSelection(row: Int)
    func onSearch(text: String)
    func onCancelSearch()
}

final public class PickCurrencyViewModelImpl: PickCurrencyViewModel {
    
    public var loaded: Box<Bool> = Box(false)
    public var error: Box<Error?> = Box(nil)
    public var symbols: Box<[SymbolModel]> = Box([])
    public var searchEnabled: Box<Bool> = Box(false)
    public var mode: PickCurrencyModeEnum = .source
    public weak var delegate: PickCurrencyViewModelDelegate?
    
    let userCase: SymbolUseCase
    
    public init() {
        self.userCase = SymbolUseCaseImpl()
    }
    
    init(useCase: SymbolUseCase = SymbolUseCaseImpl() ) {
        self.userCase = useCase
    }
    
    public func onLoad() {
        userCase.getSymbols(completion: { [weak self] result in
            guard let self = self else {
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                
                // This is to avoid thrading issues
                switch result {
                case .success(let symbols):
                    self.symbols.value = symbols.sorted(by: { $0.description < $1.description})
                case .failure(let error):
                    self.error.value = error
                }
            }
        })
    }
    
    public func onSearch(text: String) {
        // Filter current symbols
        guard let result = userCase.filterSymbols(text: text) else {
            // TODO: Error
            return
        }
        
        print("on search: \(result.count)")
        self.symbols.value = result.sorted(by: { $0.description < $1.description})
    }

    public func currencyCount() -> Int {
        print("currencyCount(): \(symbols.value.count)")
        return symbols.value.count
    }

    public func onSelection(row: Int) {
        let symbol = self.symbols.value[row]
        delegate?.onSymbolSelected(viewModel: self, symbol: symbol)
    }
    
    public func onCancelSearch() {
        guard let result = userCase.filterSymbols(text: nil) else {
            // TODO: Error
            return
        }
        
        self.symbols.value = result.sorted(by: { $0.description < $1.description})
        self.searchEnabled.value = false
    }
}
