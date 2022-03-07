//
//  CurrencyViewController.swift
//  MoneyRates
//
//  Created by Omar Gomez on 3/3/22.
//

import UIKit

class PickCurrencyViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: PickCurrencyViewModel!

    convenience init?(coder: NSCoder, viewModel: PickCurrencyViewModel) {
        self.init(coder: coder)
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.symbols.bind(listener: { [weak self] symbols in
            print("Reload data!! \(symbols.count)")
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        })
        
        viewModel.onLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellID")
    }

}

extension PickCurrencyViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.currencyCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellID") else {
            return UITableViewCell()
        }
        
        let symbol = self.viewModel.symbols.value[indexPath.row]
        cell.textLabel?.text = symbol.description
        return cell
    }
}

extension PickCurrencyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt : \(indexPath.row)")
        self.viewModel.onSelection(row: indexPath.row)
    }
}
