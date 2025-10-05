//
//  CoreDataStack.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import CoreData
import Foundation

class CoreDataStack {
    static let shared = CoreDataStack()
    
    private var isStoreLoaded = false

    private init() {
        print("🔧 CoreDataStack: Initializing...")
        // Force initialization of persistent container
        _ = persistentContainer
    }

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "GroceryBudgetOptimizer")

        // Configure CloudKit sync
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }

        // Log the store URL to verify it's not in-memory
        print("💾 CoreData: Store URL: \(description.url?.absoluteString ?? "nil")")
        print("💾 CoreData: Store type: \(description.type)")

        // Enable CloudKit sync - Optional for now, we'll enable this later
        // description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
        //     containerIdentifier: AppConstants.Database.cloudKitContainerID
        // )

        // Enable persistent history tracking
        description.setOption(true as NSNumber,
                            forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber,
                            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Load stores SYNCHRONOUSLY to ensure they're ready before use
        var loadError: Error?
        let group = DispatchGroup()
        group.enter()
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                print("❌ CoreData: Failed to load persistent store - \(error), \(error.userInfo)")
                loadError = error
            } else {
                print("✅ CoreData: Persistent store loaded successfully")
                print("✅ CoreData: Store location: \(storeDescription.url?.absoluteString ?? "unknown")")
                self?.isStoreLoaded = true
            }
            group.leave()
        }
        
        // WAIT for store to load before continuing
        group.wait()
        
        if let error = loadError {
            fatalError("Unresolved error loading persistent store: \(error)")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        print("✅ CoreData: Container fully initialized and ready")
        return container
    }()

    var viewContext: NSManagedObjectContext {
        print("🔍 CoreDataStack: Accessing viewContext (will trigger container load if not loaded)")
        return persistentContainer.viewContext
    }

    // MARK: - Background Context

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Save Context

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Error saving context: \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Error saving context: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Utilities
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = newBackgroundContext()
        context.perform {
            block(context)
        }
    }
}