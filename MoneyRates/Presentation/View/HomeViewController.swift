//
//  ViewController.swift
//  MoneyRates
//
//  Created by Omar Gomez on 21/2/22.
//

import UIKit
import Combine

extension UIViewController {
    
    func showErrorAlert(title: String, message: String) {
        let dialogMessage = UIAlertController(title: title, message: message, preferredStyle: .alert)
         
         // Create OK button with action handler
         let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
          })
         
         //Add OK button to a dialog message
         dialogMessage.addAction(ok)
         // Present Alert to
         self.present(dialogMessage, animated: true, completion: nil)
    }
    
}

class HomeViewController: UIViewController {

    var viewModel: HomeViewModel!
    
    @IBOutlet weak var targetButton: UIButton!
    @IBOutlet weak var sourceButton: UIButton!
    @IBOutlet weak var sourceField: UITextField!
    @IBOutlet weak var targetField: UITextField!
    @IBOutlet weak var busyIndicator: UIActivityIndicatorView!
    
    private var cancellables: Set<AnyCancellable> = []
    
    convenience init?(coder: NSCoder, viewModel: HomeViewModel) {
        self.init(coder: coder)
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind(output: viewModel.output())
        
        viewModel.onLoad()
    }
    

    @IBAction func onSourcePickAction(_ sender: Any) {
        viewModel.pickSourceEvent()
    }
    
    @IBAction func onTargetPickAction(_ sender: Any) {
        viewModel.pickTargetEvent()
    }
    
    @IBAction func onSourceChanged(_ sender: UITextField) {
        guard let text = sender.text else {
            return
        }
        
        viewModel.onInput(source: text)
    }
    
    @IBAction func onTargetChanged(_ sender: UITextField) {
        guard let text = sender.text else {
            return
        }
        
        viewModel.onInput(target: text)
    }
}

private extension HomeViewController {
    func bind(output: HomeViewOutput) {
        output.sourceTitle
            .receive(on: RunLoop.main)
            .sink { (title) in
                self.sourceButton.setTitle(title, for: .normal)
            }.store(in: &cancellables)
        
        output.targetTitle
            .receive(on: RunLoop.main)
            .sink { (title) in
                self.targetButton.setTitle(title, for: .normal)
        }.store(in: &cancellables)
        
        output.error
            .compactMap{ $0 }
            .receive(on: RunLoop.main)
            .sink { (error) in
                self.showErrorAlert(title: error.title, message: error.description)
        }.store(in: &cancellables)
        
        output.targetResult
            .compactMap{ $0 }
            .receive(on: RunLoop.main)
            .sink { (value) in
                self.targetField.text = String(describing: value)
        }.store(in: &cancellables)
        
        output.sourceResult
            .compactMap{ $0 }
            .receive(on: RunLoop.main)
            .sink { (value) in
                self.sourceField.text = String(describing: value)
        }.store(in: &cancellables)
                
        output.busy
            .compactMap{ $0 }
            .receive(on: RunLoop.main)
            .sink { (value) in
                self.busyIndicator.isHidden = !value
                if value {
                    self.busyIndicator.startAnimating()
                } else {
                    self.busyIndicator.stopAnimating()
                }
            }.store(in: &cancellables)
    }
}

extension HomeViewController: PickCurrencyViewModelDelegate {
    func onSymbolSelected(viewModel: PickCurrencyViewModel, symbol: SymbolModel) {
        if viewModel.mode == .source {
            self.viewModel.onSelection(source: symbol)
        } else {
            self.viewModel.onSelection(target: symbol)
        }
    }
}
