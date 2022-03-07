//
//  Coordinator.swift
//  MoneyRates
//
//  Created by Omar Gomez on 2/3/22.
//

import Foundation
import UIKit

protocol Coordinator {
    var parentCoordinator: Coordinator? { get set }
    var children: [Coordinator] { get set }
    var navigationController : UINavigationController { get set }
    
    func start()
}

protocol FlowTarget {
}

protocol FlowCoordinator {
    func start<T: FlowTarget>(_ target: T)
}

