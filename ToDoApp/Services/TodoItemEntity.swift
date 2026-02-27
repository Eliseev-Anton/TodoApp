import Foundation
import CoreData

@objc(TodoItemEntity)
final class TodoItemEntity: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var title: String?
    @NSManaged var descriptionText: String?
    @NSManaged var createdDate: Date?
    @NSManaged var isCompleted: Bool
}
