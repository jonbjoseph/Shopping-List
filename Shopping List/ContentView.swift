import SwiftUI
import CoreData


// MARK: - Core Data Models
@objc(ShoppingList)
public class ShoppingList: NSManagedObject, Identifiable {
    @NSManaged public var storeName: String
    @NSManaged public var shoppingDate: Date
    @NSManaged public var createdDate: Date
    @NSManaged public var items: NSSet?
    
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
    
    public var itemsArray: [ShoppingItem] {
        guard let itemsSet = items as? NSSet else { return [] }
        return (itemsSet.allObjects as? [ShoppingItem] ?? []).sorted { $0.itemName < $1.itemName }
    }
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        self.createdDate = Date()
        self.shoppingDate = Date()
    }
}

@objc(ShoppingItem)
public class ShoppingItem: NSManagedObject, Identifiable {
    @NSManaged public var itemName: String
    @NSManaged public var itemDescription: String
    @NSManaged public var isPurchased: Bool
    @NSManaged public var shoppingList: ShoppingList?
    
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        self.isPurchased = false
    }
}

// MARK: - Core Data Stack
class PersistenceController {
    static let shared = PersistenceController()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Shopping_List")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // For development: If migration fails, delete and recreate store
                if error.code == 134110 { // Migration error
                    self.deleteAndRecreateStore(container: container)
                } else {
                    fatalError("Core Data error: \(error), \(error.userInfo)")
                }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    private func deleteAndRecreateStore(container: NSPersistentContainer) {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            container.loadPersistentStores { _, error in
                if let error = error {
                    fatalError("Failed to recreate store: \(error)")
                }
            }
        } catch {
            fatalError("Failed to delete store: \(error)")
        }
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingList.shoppingDate, ascending: false)],
        animation: .default)
    private var shoppingLists: FetchedResults<ShoppingList>
    
    @State private var showingAddList = false
    @State private var selectedList: ShoppingList?
    @State private var showingShoppingMode = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(shoppingLists) { list in
                    ShoppingListRow(list: list)
                        .onTapGesture {
                            selectedList = list
                            showingShoppingMode = true
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                deleteList(list)
                            }
                            Button("Clone") {
                                cloneList(list)
                            }
                            .tint(.blue)
                        }
                }
            }
            .navigationTitle("Shopping Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddList = true
                    }
                }
            }
            .sheet(isPresented: $showingAddList) {
                AddShoppingListView()
            }
            .sheet(item: $selectedList) { list in
                ShoppingModeView(shoppingList: list)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func deleteList(_ list: ShoppingList) {
        withAnimation {
            viewContext.delete(list)
            PersistenceController.shared.save()
        }
    }
    
    private func cloneList(_ list: ShoppingList) {
        let newList = ShoppingList(context: viewContext)
        newList.storeName = list.storeName + " (Copy)"
        newList.shoppingDate = Date()
        
        for item in list.itemsArray {
            let newItem = ShoppingItem(context: viewContext)
            newItem.itemName = item.itemName
            newItem.itemDescription = item.itemDescription
            newItem.shoppingList = newList
        }
        
        PersistenceController.shared.save()
    }
}

// MARK: - Shopping List Row
struct ShoppingListRow: View {
    let list: ShoppingList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(list.storeName)
                .font(.headline)
            Text(list.shoppingDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Text("\(list.itemsArray.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                let purchasedCount = list.itemsArray.filter { $0.isPurchased }.count
                Text("\(purchasedCount) purchased")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Shopping List View
struct AddShoppingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var storeName = ""
    @State private var shoppingDate = Date()
    @State private var selectedTemplate: ShoppingList?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingList.shoppingDate, ascending: false)],
        animation: .default)
    private var existingLists: FetchedResults<ShoppingList>
    
    var body: some View {
        NavigationView {
            Form {
                Section("List Details") {
                    TextField("Store Name", text: $storeName)
                    DatePicker("Shopping Date", selection: $shoppingDate, displayedComponents: .date)
                }
                
                Section("Template (Optional)") {
                    Picker("Use Template", selection: $selectedTemplate) {
                        Text("Create from scratch").tag(nil as ShoppingList?)
                        ForEach(existingLists) { list in
                            Text("\(list.storeName) - \(list.shoppingDate, style: .date)")
                                .tag(list as ShoppingList?)
                        }
                    }
                }
            }
            .navigationTitle("New Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveList()
                    }
                    .disabled(storeName.isEmpty)
                }
            }
        }
    }
    
    private func saveList() {
        let newList = ShoppingList(context: viewContext)
        newList.storeName = storeName
        newList.shoppingDate = shoppingDate
        
        // Clone items from template if selected
        if let template = selectedTemplate {
            for item in template.itemsArray {
                let newItem = ShoppingItem(context: viewContext)
                newItem.itemName = item.itemName
                newItem.itemDescription = item.itemDescription
                newItem.shoppingList = newList
            }
        }
        
        PersistenceController.shared.save()
        dismiss()
    }
}

// MARK: - Shopping Mode View
struct ShoppingModeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var shoppingList: ShoppingList
    @State private var showingAddItem = false
    @State private var editingItem: ShoppingItem?
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with store info
                VStack(alignment: .leading, spacing: 8) {
                    Text(shoppingList.storeName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(shoppingList.shoppingDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    let totalItems = shoppingList.itemsArray.count
                    let purchasedItems = shoppingList.itemsArray.filter { $0.isPurchased }.count
                    Text("\(purchasedItems) of \(totalItems) items purchased")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Items list
                List {
                    ForEach(shoppingList.itemsArray) { item in
                        ShoppingItemRow(item: item) {
                            editingItem = item
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Shopping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Item") {
                        showingAddItem = true
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView(shoppingList: shoppingList)
            }
            .sheet(item: $editingItem) { item in
                EditItemView(item: item)
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { shoppingList.itemsArray[$0] }.forEach(viewContext.delete)
            PersistenceController.shared.save()
        }
    }
}

// MARK: - Shopping Item Row
struct ShoppingItemRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: ShoppingItem
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                item.isPurchased.toggle()
                PersistenceController.shared.save()
            }) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isPurchased ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemName)
                    .font(.body)
                    .strikethrough(item.isPurchased)
                    .foregroundColor(item.isPurchased ? .secondary : .primary)
                
                if !item.itemDescription.isEmpty {
                    Text(item.itemDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Edit") {
                onEdit()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Item View
struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let shoppingList: ShoppingList
    @State private var itemName = ""
    @State private var itemDescription = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $itemName)
                    TextField("Description (Optional)", text: $itemDescription)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
        }
    }
    
    private func saveItem() {
        let newItem = ShoppingItem(context: viewContext)
        newItem.itemName = itemName
        newItem.itemDescription = itemDescription
        newItem.shoppingList = shoppingList
        
        PersistenceController.shared.save()
        dismiss()
    }
}

// MARK: - Edit Item View
struct EditItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var item: ShoppingItem
    @State private var itemName = ""
    @State private var itemDescription = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $itemName)
                    TextField("Description (Optional)", text: $itemDescription)
                }
                
                Section("Status") {
                    Toggle("Purchased", isOn: Binding(
                        get: { item.isPurchased },
                        set: { item.isPurchased = $0 }
                    ))
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
            .onAppear {
                itemName = item.itemName
                itemDescription = item.itemDescription
            }
        }
    }
    
    private func saveChanges() {
        item.itemName = itemName
        item.itemDescription = itemDescription
        PersistenceController.shared.save()
        dismiss()
    }
}

// MARK: - Core Data Model Extensions
extension ShoppingList {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingList> {
        return NSFetchRequest<ShoppingList>(entityName: "ShoppingList")
    }
}

extension ShoppingItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingItem> {
        return NSFetchRequest<ShoppingItem>(entityName: "ShoppingItem")
    }
}
