import Foundation
@testable import ToDoApp

enum TestData {

    static func makeTodo(
        id: Int64 = 1,
        title: String = "Тестовая задача",
        description: String = "Описание",
        completed: Bool = false
    ) -> TodoItem {
        TodoItem(
            id: id,
            title: title,
            descriptionText: description,
            createdDate: Date(),
            isCompleted: completed
        )
    }

    static func makeTodoList(count: Int = 5) -> [TodoItem] {
        (1...count).map { i in
            makeTodo(id: Int64(i), title: "Задача \(i)", description: "Описание \(i)")
        }
    }

    static let apiJSON = """
    {
        "todos": [
            {"id": 1, "todo": "Buy groceries", "completed": false, "userId": 1},
            {"id": 2, "todo": "Clean house", "completed": true, "userId": 2}
        ],
        "total": 2,
        "skip": 0,
        "limit": 30
    }
    """.data(using: .utf8)!
}
