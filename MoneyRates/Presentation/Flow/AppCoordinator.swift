//
//  AppCoordinator.swift
//  MoneyRates
//
//  Created by Omar Gomez on 2/3/22.
//

import Foundation
import UIKit


protocol AppCoordinator {
    func goToHome()
}

final class AppCoordinatorImpl: AppCoordinator {
    
    private weak var window: UIWindow!
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func goToHome() {
        
        guard let navigationController = UIStoryboard.main.instantiateInitialViewController() as? UINavigationController else {
            return
        }
        
        navigationController.setViewControllers([getUIController()], animated: false)
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

    }
    
}

private extension AppCoordinatorImpl {
    func getController() -> UIViewController {
       UIStoryboard.main.instantiateViewController(identifier: "homeController", creator: { coder in
            
            let viewModel = HomeViewModelImpl()
            guard let result = HomeViewController(coder: coder, viewModel: viewModel) else {
                fatalError("HomeViewController failed")
            }
//            viewModel.coordinator = HomeCoordinatorImpl(parentController: result)
            return result
            
        })
    }
    
    func getUIController() -> UIViewController {
        let viewModel = HomeViewModelImpl()
        let result = HomeHostingController(viewModel: viewModel)
        viewModel.coordinator = HomeCoordinatorImpl(parentController: result)
        return result
    }
}

