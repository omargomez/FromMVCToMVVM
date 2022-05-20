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
    private let loadSubject = PassthroughSubject<Void, Never>()
    private let inputSourceSubject = PassthroughSubject<String, Never>()
    private let inputTargetSubject = PassthroughSubject<String, Never>()
    private let pickSourceSubject = PassthroughSubject<Void, Never>()
    private let pickTargetSubject = PassthroughSubject<Void, Never>()
    private let onSourceSubject = PassthroughSubject<SymbolModel, Never>()
    private let onTargetSubject = PassthroughSubject<SymbolModel, Never>()
    
    convenience init?(coder: NSCoder, viewModel: HomeViewModel) {
        self.init(coder: coder)
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind(sourceTitle: viewModel.sourceTitle.eraseToAnyPublisher(),
             targetTitle: viewModel.targetTitle.eraseToAnyPublisher(),
             error: viewModel.error.eraseToAnyPublisher(),
             targetResult: viewModel.targetResult.eraseToAnyPublisher(),
             sourceResult: viewModel.sourceResult.eraseToAnyPublisher(),
             busy: viewModel.busy.eraseToAnyPublisher()
        )
        
        viewModel.bind(onLoad: loadSubject.eraseToAnyPublisher(),
                       onInputSource: inputSourceSubject.eraseToAnyPublisher(),
                       onInputTarget: inputTargetSubject.eraseToAnyPublisher(),
                       pickSourceEvent: pickSourceSubject.eraseToAnyPublisher(),
                       pickTargetEvent: pickTargetSubject.eraseToAnyPublisher(),
                       onSource: onSourceSubject.eraseToAnyPublisher(),
                       onTarget: onTargetSubject.eraseToAnyPublisher())
        
        loadSubject.send(())
        
    }
    

    @IBAction func onSourcePickAction(_ sender: Any) {
        pickSourceSubject.send(())
    }
    
    @IBAction func onTargetPickAction(_ sender: Any) {
        pickTargetSubject.send(())
    }
    
    @IBAction func onSourceChanged(_ sender: UITextField) {
        guard let text = sender.text else {
            return
        }
        
        inputSourceSubject.send(text)
    }
    
    @IBAction func onTargetChanged(_ sender: UITextField) {
        guard let text = sender.text else {
            return
        }
        
        inputTargetSubject.send(text)
    }
}

extension HomeViewController {
    private func bind(sourceTitle: AnyPublisher<String?, Never>,
        targetTitle: AnyPublisher<String?, Never>,
        error: AnyPublisher<ErrorViewModel?, Never>,
        targetResult: AnyPublisher<AmountViewModel?, Never>,
        sourceResult: AnyPublisher<AmountViewModel?, Never>,
        busy: AnyPublisher<Bool, Never>
    ) {
        
        sourceTitle
            .receive(on: RunLoop.main)
            .sink { (title) in
                self.sourceButton.setTitle(title, for: .normal)
            }.store(in: &cancellables)
        
        targetTitle
            .receive(on: RunLoop.main)
            .sink { (title) in
                self.targetButton.setTitle(title, for: .normal)
        }.store(in: &cancellables)
        
        error
            .compactMap{ $0 }
            .receive(on: RunLoop.main)
            .sink { (error) in
                self.showErrorAlert(title: error.title, message: error.description)
        }.store(in: &cancellables)
        
        targetResult
            .compactMap{ $0 }
            .receive(on: RunLoop.main)
            .sink { (value) in
                self.targetField.text = String(describing: value)
        }.store(in: &cancellables)
        
        sourceResult
            .compactMap{ $0 }
            .receive(on: RunLoop.main)
            .sink { (value) in
                self.sourceField.text = String(describing: value)
        }.store(in: &cancellables)
        
        
        busy
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
            onSourceSubject.send(symbol)
        } else {
            onTargetSubject.send(symbol)
        }
    }
}
