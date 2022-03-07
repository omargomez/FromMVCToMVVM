//
//  SymbolRepository.swift
//  MoneyRates
//
//  Created by Omar Gomez on 21/2/22.
//

import Foundation
import CoreData

extension NSPersistentContainer {
    
    static let moneyRates: NSPersistentContainer = {
        let result = NSPersistentContainer(name: "MoneyRates")
        let semaphore = DispatchSemaphore(value: 0)
        
        result.loadPersistentStores(completionHandler: { desc, error in
            if let error = error {
                fatalError("Can't load store!")
            }
            semaphore.signal()
        })
        semaphore.wait()
        return result
    }()
    
}

protocol SymbolRepository {
    
    func reset(apiItems: [APISymbolsItem], completion: @escaping (Result<Void, Error>) -> Void )
    func getAll() -> [SymbolEntity]?
    func getSymbol(code: String) -> SymbolEntity?
    func count() throws -> Int
}

class SymbolRepositoryImpl: SymbolRepository {
    
    let container: NSPersistentContainer
    
    init(container: NSPersistentContainer = NSPersistentContainer.moneyRates) {
        self.container = container
    }
    
    
    func reset(apiItems: [APISymbolsItem], completion: @escaping (Result<Void, Error>) -> Void ) {
        // BKG Operation
        container.performBackgroundTask({ [weak self] context in
            guard let self = self else { return }

            do {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SymbolEntity")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try self.container.persistentStoreCoordinator.execute(deleteRequest, with: context)
                
                for item in apiItems {
                    let newEntity = SymbolEntity(context: context)
                    newEntity.code = item.code
                    newEntity.symbolDescription = item.descripton
                }
                
                try context.save()
                completion(.success(()))
            } catch {
                context.rollback()
                completion(.failure(error))
            }
        })
    }
    
    func getAll() -> [SymbolEntity]? {
        // Not too many can be done from mainView
        do {
            let fetchReq = NSFetchRequest<SymbolEntity>(entityName: "SymbolEntity")
            return try container.viewContext.fetch(fetchReq)
        } catch {
            return nil
        }
        
    }
    
    func getSymbol(code: String) -> SymbolEntity? {
        do {
            let fetchReq = NSFetchRequest<SymbolEntity>(entityName: "SymbolEntity")
            fetchReq.predicate = NSPredicate(format: "code = %@", code)
            return try container.viewContext.fetch(fetchReq).first
        } catch {
            return nil
        }
    }
    
    func count() throws -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SymbolEntity")
        return try container.viewContext.count(for: fetchRequest)

    }
}
