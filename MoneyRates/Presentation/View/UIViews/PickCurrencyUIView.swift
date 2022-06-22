//
//  PickCurrencyUIView.swift
//  MoneyRates
//
//  Created by Omar Eduardo Gomez Padilla on 8/06/22.
//

import SwiftUI
import Combine

struct PickCurrencyUIView: View {
    
    class Model: ObservableObject {
        
        private var viewModel: PickCurrencyViewModel?
        @Published var symbols: [SymbolModel] = []
        
        //Inputs
        private let loadSubject = PassthroughSubject<Void, Never>()
        private let onSelectionSubject = PassthroughSubject<Int, Never>()
        private let cancelSubject = PassthroughSubject<Void, Never>()
        private var searchSubject = PassthroughSubject<String, Never>()

        init(viewModel: PickCurrencyViewModel? = nil) {
            self.viewModel = viewModel
        }
        
    }
    
    @ObservedObject private var model: Model
    @State private var searchText: String
    
    init(viewModel: PickCurrencyViewModel? = PickCurrencyViewModelImpl()) {
        self.model = Model(viewModel: viewModel)
        self.searchText = ""
    }
    
    private typealias RowItem = (index: Int, item: SymbolModel)
    
    var body: some View {
        let items = (0..<model.symbols.count).map{$0}.map({RowItem(index: $0, self.model.symbols[$0])})
        VStack {
            SearchBar(text: $searchText)
                .padding(.top, 30)
            List(items, id: \.item.id) { symbolItem in
                Button(action: {
                    self.model.onSelection(symbolItem.index)
                }) {
                    Text(symbolItem.item.description)
                }
            }
            .onAppear(perform: {
                self.model.onLoad()
            })
            .onChange(of: searchText) { newValue in
                self.model.onQuery(newValue)
            }
        }
    }
    
}

struct PickCurrencyUIView_Previews: PreviewProvider {
    static var previews: some View {
        PickCurrencyUIView()
    }
}

extension PickCurrencyUIView.Model {

    func onLoad() {
        let output = viewModel!.bind(input: PickCurrencyViewInput(
            onLoad: loadSubject.eraseToAnyPublisher(),
            onSelection: onSelectionSubject.eraseToAnyPublisher(),
            cancelSearch: cancelSubject.eraseToAnyPublisher(),
            search: searchSubject.eraseToAnyPublisher()))
        
        bind(output: output)
        self.loadSubject.send()
    }
    
    func onQuery(_ text: String) {
        searchSubject.send(text)
    }

    func onSelection(_ index: Int) {
        self.onSelectionSubject.send(index)
    }

    func bind(output: PickCurrencyViewOutput) {
        output.symbols
            .assign(to: &$symbols)
        
        #if false
        output.searchEnabled
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.searchBar.text = nil
                self?.searchBar.resignFirstResponder()
            })
            .store(in: &cancellables)

        output.error
            .compactMap{ $0 }
            .receive(on: RunLoop.main)
            .sink { (error) in
                self.showErrorAlert(title: error.title, message: error.description)
            }
            .store(in: &cancellables)
        #endif
        
    }
}

struct SearchBar: View {
    @Binding var text: String
 
    @State private var isEditing = false
 
    var body: some View {
        HStack {
 
            TextField("Search ...", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 10)
                .onTapGesture {
                    self.isEditing = true
                }
 
            if isEditing {
                Button(action: {
                    self.isEditing = false
                    self.text = ""
 
                }) {
                    Text("Cancel")
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default)
            }
        }
    }
}
