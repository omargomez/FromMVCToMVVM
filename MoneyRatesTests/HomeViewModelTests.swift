//
//  MoneyRatesTests.swift
//  MoneyRatesTests
//
//  Created by Omar Gomez on 21/2/22.
//

import XCTest
import CoreData
@testable import MoneyRates

extension NSPersistentContainer {
    
    static func tempContainer() -> NSPersistentContainer {
        let result = NSPersistentContainer(name: "MoneyRates")
       
        if let storeDescription = result.persistentStoreDescriptions.first {
            storeDescription.shouldAddStoreAsynchronously = true
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
            storeDescription.shouldAddStoreAsynchronously = false
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        result.loadPersistentStores(completionHandler: { desc, error in
            if let error = error {
                fatalError("DataStack creation error! \(error.localizedDescription)")
            } else {
                semaphore.signal()
            }
        })
        
        semaphore.wait()
        return result
    }

}

extension Bundle {
    
    func load(name: String) -> [[String: String]] {
        
        guard let path = self.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: path),
              let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let symbols = dict["symbols"] as? [String: Any] else {
                  
                  fatalError("JSON File load error!")
              }
        
        return symbols.values.compactMap({ $0 as? [String: String] })
    }
    
}


class ExchangeRateMock: ExchangeRateService {
    func symbols(completion: @escaping (Result<[APISymbolsItem], Error>) -> Void) {
        let result: [APISymbolsItem] = Bundle(for: type(of: self)).load(name: "symbols").compactMap({ item in
            guard let code = item["code"], let desc = item["description"] else {
                return nil
            }
            return APISymbolsItem(code: code, descripton: desc)
        })
        completion(.success(result))
    }
}

class HomeViewModelTests: XCTestCase {
    
    var sut: HomeViewModel!

    override func setUpWithError() throws {
        let repository = SymbolRepositoryImpl(container: NSPersistentContainer.tempContainer())
        let service = ExchangeRateMock()

        self.sut = HomeViewModelImpl(symbolRepository: repository, exchangeService: service)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoaadView() throws {
        
        let exp = expectation(description: "load expectation")
        sut.symbols.bind(listener: { value in
            guard !value.isEmpty else {
                return
            }
            exp.fulfill()
        })
        
        sut.onLoadView()
        wait(for: [exp], timeout: 10.0)
        
    }

}
