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
    
    private weak var parentController: HomeViewController!
    
    init(parentController: HomeViewController) {
        self.parentController = parentController
    }
    
    func goToPickSource() {
        let controller  = getController()
        controller.viewModel.mode = .source
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
}

extension HomeCoordinatorImpl: PickCurrencyViewModelDelegate {
    func onSymbolSelected(viewModel: PickCurrencyViewModel, symbol: SymbolModel) {
        print("onSymbolSelected \(symbol.description)")
        parentController.presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            // Tell the model
            if viewModel.mode == .source {
                self?.parentController.viewModel.onSource(symbol: symbol)
            } else {
                self?.parentController.viewModel.onTarget(symbol: symbol)
            }
        })
    }
    
    
}
