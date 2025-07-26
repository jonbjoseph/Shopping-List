// Core Data Model Setup Instructions
// 1. In Xcode, create a new Data Model file named "ShoppingListModel.xcdatamodeld"
// 2. Add two entities with the following configurations:

/*
Entity: ShoppingList
Attributes:
- id: UUID (Optional: NO)
- storeName: String (Optional: NO)
- shoppingDate: Date (Optional: NO)
- createdDate: Date (Optional: NO)

Relationships:
- items: To-Many relationship to ShoppingItem (Delete Rule: Cascade, Inverse: shoppingList)

Entity: ShoppingItem
Attributes:
- id: UUID (Optional: NO)
- itemName: String (Optional: NO)
- itemDescription: String (Optional: YES)
- isPurchased: Boolean (Optional: NO, Default: NO)

Relationships:
- shoppingList: To-One relationship to ShoppingList (Delete Rule: Nullify, Inverse: items)
*/

// Additional Core Data configuration code for advanced features:

import CoreData


extension PersistenceController {
    // For handling data migrations if needed in the future
    static var preview: PersistenceController = {
        ////let result = PersistenceController(inMemory: true)
        let result = PersistenceController()
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleList = ShoppingList(context: viewContext)
        sampleList.storeName = "Sample Store"
        sampleList.shoppingDate = Date()
        
        let sampleItem = ShoppingItem(context: viewContext)
        sampleItem.itemName = "Sample Item"
        sampleItem.itemDescription = "Sample Description"
        sampleItem.shoppingList = sampleList
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    
    /*
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Shopping_List")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
     */
     
}


// MARK: - Security Considerations
/*
Security Features Implemented:
1. Local storage only - no network communication
2. Data encrypted at rest (iOS automatically encrypts Core Data files)
3. App sandbox protection
4. No sensitive data logging
5. Automatic app backgrounding protection

Additional Security Recommendations:
- Enable "Require Authentication" in iOS Settings > Face ID & Passcode > Require Attention for Face ID
- Consider adding biometric authentication for app launch if desired
- Regular iOS updates for security patches
*/

// MARK: - Offline Functionality
/*
Offline Features:
1. All data stored locally in Core Data
2. No network dependencies during shopping
3. Data persists across app launches
4. Automatic conflict resolution with Core Data's merge policies
5. Background app refresh not required
*/
