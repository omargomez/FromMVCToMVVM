//
//  ExchangeRateService.swift
//  MoneyRates
//
//  Created by Omar Gomez on 21/2/22.
//

import Foundation

enum ExchangeRateServiceError: LocalizedError {
    case urlError
    case noDataError
    case serializationError
    case netError(Error)
    
    var errorDescription: String? {
        switch self {
        case .urlError:
                return "urlError"
        case .noDataError:
                return "noDataError"
        case .serializationError:
                return "serializationError"
        case .netError(let error):
            return "Net Error: \(error.localizedDescription)"
        }
    }
}

protocol ExchangeRateService {
    
    func symbols(completion: @escaping (Result<[APISymbolsItem], Error>) -> Void)
    func convert(sourceSymbol: String, targetSymbol: String, amount: Double, completion: @escaping (Result<Double, Error>) -> Void)
    
}

class ExchangeRateServiceImpl: ExchangeRateService {
    
    func symbols(completion: @escaping (Result<[APISymbolsItem], Error>) -> Void) {
        guard let symbolUrl = URL(string: "https://api.exchangerate.host/symbols") else {
            completion(.failure(ExchangeRateServiceError.urlError))
            return
        }
        
        NSLog("calling symbols...")
        URLSession.shared.dataTask(with: symbolUrl, completionHandler: { data, response, error in
            guard let data = data else {
                if let error = error {
                    NSLog("Symbols Error!")
                    completion(.failure(ExchangeRateServiceError.netError(error)))
                } else {
                    NSLog("Symbols Error!")
                    completion(.failure(ExchangeRateServiceError.noDataError))
                }
                return
            }
            
            // Deserialize the thing
            guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let symbols = dict["symbols"] as? [String: Any],
                  symbols.count > 0 else {
                      NSLog("Symbols Error!")
                      completion(.failure(ExchangeRateServiceError.serializationError))
                      return
            }
            
            completion(.success(symbols.values.compactMap({ $0 as? [String: String] }).map({ APISymbolsItem(code: $0["code"] ?? "--", descripton: $0["description"] ?? "--") })))
        }).resume()
    }
    
    func convert(sourceSymbol: String, targetSymbol: String, amount: Double, completion: @escaping (Result<Double, Error>) -> Void) {
        guard let url = URL(string: "https://api.exchangerate.host/convert?from=\(sourceSymbol)&to=\(targetSymbol)&amount=\(amount)") else {
            completion(.failure(ExchangeRateServiceError.urlError))
            return
        }
        
        NSLog("convert, calling...\(url)")
        URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            guard let data = data else {
                if let error = error {
                    completion(.failure(ExchangeRateServiceError.netError(error)))
                } else {
                    completion(.failure(ExchangeRateServiceError.noDataError))
                }
                return
            }
            
            // Deserialize the thing
            guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = dict["result"] as? Double else {
                completion(.failure(ExchangeRateServiceError.serializationError))
                return
            }
            
            completion(.success(result))
        }).resume()
        
    }
    
}
