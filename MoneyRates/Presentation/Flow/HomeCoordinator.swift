//
//  HomeCoordinator.swift
//  MoneyRates
//
//  Created by Omar Gomez on 3/3/22.
//

import Foundation
import UIKit

protocol HomeCoordinator {
    func goToPickSource()
    func goToPickTarget()
}

final class HomeCoordinatorImpl: HomeCoordinator {
    
    private weak var parentController: HomeHostingController!
    
    init(parentController: HomeHostingController) {
        self.parentController = parentController
    }
    
    func goToPickSource() {
        let controller  = getUIController()
        parentController.present(controller, animated: true)
    }
    
    func goToPickTarget() {
        let controller  = getController()
        controller.viewModel.mode = .target
        parentController.present(controller, animated: true)
    }
}

extension HomeCoordinatorImpl {
    
    private func getController() -> PickCurrencyViewController {
        let controller = UIStoryboard.main.instantiateViewController(identifier: "currencyViewController", creator: { coder in
            let viewModel = PickCurrencyViewModelImpl()
            viewModel.delegate = self
            let result = PickCurrencyViewController(coder: coder, viewModel: viewModel)
            return result
        }) as! PickCurrencyViewController
        return controller
    }
    
    private func getUIController() -> PickCurrencyUIViewController {
        let viewModel = PickCurrencyViewModelImpl()
        viewModel.delegate = self
        return PickCurrencyUIViewController(viewModel: viewModel)
    }
}

extension HomeCoordinatorImpl: PickCurrencyViewModelDelegate {
    func onSymbolSelected(viewModel: PickCurrencyViewModel, symbol: SymbolModel) {
        print("onSymbolSelected \(symbol.description)")
        parentController.presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            // Tell the model
            self?.parentController.onSymbolSelected(viewModel: viewModel, symbol: symbol)
        })
    }
}
