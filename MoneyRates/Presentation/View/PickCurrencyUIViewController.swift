//
//  PickCurrencyUIViewController.swift
//  MoneyRates
//
//  Created by Omar Gomez on 10/6/22.
//

import Foundation
import SwiftUI

class PickCurrencyUIViewController: UIHostingController<PickCurrencyUIView> {

    init(viewModel: PickCurrencyViewModel) {
        super.init(rootView: PickCurrencyUIView(viewModel: viewModel))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
