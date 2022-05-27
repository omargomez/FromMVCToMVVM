//
//  PickCurrencyViewModel.swift
//  MoneyRates
//
//  Created by Omar Gomez on 3/3/22.
//

import Foundation
import Combine

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
    var delegate: PickCurrencyViewModelDelegate? { get set }
    
    func currencyCount() -> Int
    func symbolAt(at: Int) -> SymbolModel
    
    //Combine
    var symbols: AnyPublisher<[SymbolModel], Never> { get }
    var error: AnyPublisher<ErrorViewModel, Never> { get }
    var searchEnabled: AnyPublisher<Bool, Never> { get }
    
    func bind(onLoad: AnyPublisher<Void, Never>,
              onSelection: AnyPublisher<Int, Never>,
              cancelSearch: AnyPublisher<Void, Never>,
              search: AnyPublisher<String, Never>)
    
}

final class PickCurrencyViewModelImpl: PickCurrencyViewModel {
    
    var mode: PickCurrencyModeEnum = .source
    weak var delegate: PickCurrencyViewModelDelegate?
    
    let userCase: SymbolUseCase
    
    // Combine
    @Published private(set) var _error: ErrorViewModel? = nil
    @Published private(set) var _searchEnabled: Bool = false
    @Published private(set) var _symbols: [SymbolModel] = []
    
    var error: AnyPublisher<ErrorViewModel, Never> {
        $_error.compactMap({$0}).eraseToAnyPublisher()
    }
    
    var searchEnabled: AnyPublisher<Bool, Never> {
        $_searchEnabled.eraseToAnyPublisher()
    }
    
    var symbols: AnyPublisher<[SymbolModel], Never> {
        $_symbols.filter({!$0.isEmpty}).eraseToAnyPublisher()
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(useCase: SymbolUseCase = SymbolUseCaseImpl() ) {
        self.userCase = useCase
    }
    
    func currencyCount() -> Int {
        return _symbols.count
    }

    func symbolAt(at: Int) -> SymbolModel {
        _symbols[at]
    }
    
    func bind(onLoad: AnyPublisher<Void, Never>,
              onSelection: AnyPublisher<Int, Never>,
              cancelSearch: AnyPublisher<Void, Never>,
              search: AnyPublisher<String, Never>) {
        
        typealias SymbolsType = Result<[SymbolModel], Error>
        onLoad
            .map({
                self.userCase.symbols()
                    .map({$0.sorted(by:{$0.description < $1.description})})
                    .map({ val -> SymbolsType in
                    return .success(val)
                })
                .catch({ error -> Just<SymbolsType> in
                    return Just(.failure(error))
                })
            })
            .switchToLatest()
            .sink(receiveValue: { value in
                switch value {
                case .success(let symbols):
                    self._symbols = symbols
                case .failure(let error):
                    self._error = ErrorViewModel(error: error)
                }
            })
            .store(in: &cancellables)
        
        search
            .compactMap({self.userCase.filterSymbols(text: $0)})
            .compactMap({$0.sorted(by:{$0.description < $1.description})})
            .assign(to: &$_symbols)
            
        cancelSearch
            .compactMap({self.userCase.filterSymbols(text: nil)})
            .compactMap({$0.sorted(by:{$0.description < $1.description})})
            .sink(receiveValue: { value in
                self._symbols = value
                self._searchEnabled = false
            })
            .store(in: &cancellables)
            
        onSelection
            .sink(receiveValue: { value in
                let symbol = self._symbols[value]
                self.delegate?.onSymbolSelected(viewModel: self, symbol: symbol)
            })
            .store(in: &cancellables)
    }
}
