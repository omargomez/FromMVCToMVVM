//
//  PickCurrencyViewModel.swift
//  MoneyRates
//
//  Created by Omar Gomez on 3/3/22.
//

import Foundation
import Combine

struct ErrorViewModel: Equatable {
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

struct PickCurrencyViewInput {
    let onLoad: AnyPublisher<Void, Never>
    let onSelection: AnyPublisher<Int, Never>
    let cancelSearch: AnyPublisher<Void, Never>
    let search: AnyPublisher<String, Never>
}

struct PickCurrencyViewOutput {
    let symbols: AnyPublisher<[SymbolModel], Never>
    let error: AnyPublisher<ErrorViewModel, Never>
    let searchEnabled: AnyPublisher<Bool, Never>
}

protocol PickCurrencyViewModel {
    
    var mode: PickCurrencyModeEnum { get set }
    var delegate: PickCurrencyViewModelDelegate? { get set }
    
    func currencyCount() -> Int
    func symbolAt(at: Int) -> SymbolModel
    
    func bind(input: PickCurrencyViewInput) -> PickCurrencyViewOutput
}

final class PickCurrencyViewModelImpl: PickCurrencyViewModel {
    
    var mode: PickCurrencyModeEnum = .source
    weak var delegate: PickCurrencyViewModelDelegate?
    
    let userCase: SymbolUseCase
    
    // Combine
    @Published private(set) var error: ErrorViewModel? = nil
    @Published private(set) var searchEnabled: Bool = false
    @Published private(set) var symbols: [SymbolModel] = []
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(useCase: SymbolUseCase = SymbolUseCaseImpl() ) {
        self.userCase = useCase
    }
    
    func currencyCount() -> Int {
        return symbols.count
    }

    func symbolAt(at: Int) -> SymbolModel {
        symbols[at]
    }
    
    func bind(input: PickCurrencyViewInput) -> PickCurrencyViewOutput {
        typealias SymbolsType = Result<[SymbolModel], Error>
        input.onLoad
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
                    self.symbols = symbols
                case .failure(let error):
                    self.error = ErrorViewModel(error: error)
                }
            })
            .store(in: &cancellables)
        
        input.search
            .compactMap({self.userCase.filterSymbols(text: $0)})
            .compactMap({$0.sorted(by:{$0.description < $1.description})})
            .assign(to: &$symbols)
            
        input.cancelSearch
            .compactMap({self.userCase.filterSymbols(text: nil)})
            .compactMap({$0.sorted(by:{$0.description < $1.description})})
            .sink(receiveValue: { value in
                self.symbols = value
                self.searchEnabled = false
            })
            .store(in: &cancellables)
            
        input.onSelection
            .sink(receiveValue: { value in
                let symbol = self.symbols[value]
                self.delegate?.onSymbolSelected(viewModel: self, symbol: symbol)
            })
            .store(in: &cancellables)
        
        return PickCurrencyViewOutput(
                symbols: $symbols.filter({!$0.isEmpty}).eraseToAnyPublisher(),
                error: $error.compactMap({$0}).eraseToAnyPublisher(),
                searchEnabled: $searchEnabled.eraseToAnyPublisher())
    }
}
