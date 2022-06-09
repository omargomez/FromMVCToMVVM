//
//  PickCurrencyUIView.swift
//  MoneyRates
//
//  Created by Omar Eduardo Gomez Padilla on 8/06/22.
//

import SwiftUI

struct PickCurrencyUIView: View {
    
    class Model: ObservableObject {
        
        private var viewModel: PickCurrencyViewModel?
        
        init(viewModel: PickCurrencyViewModel? = nil) {
            self.viewModel = viewModel
        }
    }
    
    private let model: Model
    
    
    init(viewModel: PickCurrencyViewModel? = nil) {
        self.model = Model(viewModel: viewModel)
    }
    
    var body: some View {
        Text("Omar Gomez 🎊")
    }
}

struct PickCurrencyUIView_Previews: PreviewProvider {
    static var previews: some View {
        PickCurrencyUIView()
    }
}

extension PickCurrencyUIView.Model {
    
}
