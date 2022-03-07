//
//  ViewController.swift
//  MoneyRates
//
//  Created by Omar Gomez on 21/2/22.
//

import UIKit

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
    
    convenience init?(coder: NSCoder, viewModel: HomeViewModel) {
        self.init(coder: coder)
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.error.bind(listener: { [weak self] error in
            guard let self = self, let error = error else {
                return
            }

            DispatchQueue.main.async {
                self.showErrorAlert(title: error.title, message: error.description)
            }
        })

        viewModel.sourceTitle.bind(listener: { [weak self] title in
            guard let self = self, let title = title else {
                return
            }
            DispatchQueue.main.async {
                self.sourceButton.setTitle(title, for: .normal)
            }
        })

        viewModel.targetTitle.bind(listener: { [weak self] title in
            guard let self = self, let title = title else {
                return
            }
            DispatchQueue.main.async {
                self.targetButton.setTitle(title, for: .normal)
            }
        })
        
        viewModel.targetResult.bind(listener: { [weak self] value in
            guard let self = self, let value = value else {
                return
            }
            DispatchQueue.main.async {
                self.targetField.text = String(describing: value)
            }
        })
        
        viewModel.busy.bind(listener: { [weak self] value in
            guard let self = self else {
                return
            }
            
            DispatchQueue.main.async {
                self.busyIndicator.isHidden = !value
                if value {
                    self.busyIndicator.startAnimating()
                } else {
                    self.busyIndicator.stopAnimating()
                }
            }
        })
                                   
        viewModel.onLoadView()
    }

    @IBAction func onSourcePickAction(_ sender: Any) {
        viewModel.pickSource()
    }
    
    @IBAction func onTargetPickAction(_ sender: Any) {
        viewModel.pickTarget()
    }
    
    @IBAction func onSourceChanged(_ sender: UITextField) {
        guard let text = sender.text else {
            return
        }
        
        viewModel.sourceChanged(input: text)
    }
    
}
