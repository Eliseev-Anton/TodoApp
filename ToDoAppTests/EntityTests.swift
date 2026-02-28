import XCTest
@testable import ToDoApp

final class EntityTests: XCTestCase {

    // MARK: - TodoItem

    func test_todoItem_creation() {
        let date = Date()
        let item = TodoItem(
            id: 1,
            title: "Test",
            descriptionText: "Desc",
            createdDate: date,
            isCompleted: false
        )

        XCTAssertEqual(item.id, 1)
        XCTAssertEqual(item.title, "Test")
        XCTAssertEqual(item.descriptionText, "Desc")
        XCTAssertEqual(item.createdDate, date)
        XCTAssertFalse(item.isCompleted)
    }

    func test_todoItem_isMutable() {
        var item = TestData.makeTodo(id: 1, title: "Original")
        item.title = "Updated"
        item.isCompleted = true

        XCTAssertEqual(item.title, "Updated")
        XCTAssertTrue(item.isCompleted)
    }

    // MARK: - API Decoding

    func test_todoAPIResponse_decodesFromJSON() throws {
        let response = try JSONDecoder().decode(TodoAPIResponse.self, from: TestData.apiJSON)

        XCTAssertEqual(response.todos.count, 2)
    }

    func test_todoAPIItem_decodesCorrectFields() throws {
        let response = try JSONDecoder().decode(TodoAPIResponse.self, from: TestData.apiJSON)
        let first = response.todos[0]

        XCTAssertEqual(first.id, 1)
        XCTAssertEqual(first.todo, "Buy groceries")
        XCTAssertFalse(first.completed)
        XCTAssertEqual(first.userId, 1)
    }

    func test_todoAPIItem_decodesCompletedStatus() throws {
        let response = try JSONDecoder().decode(TodoAPIResponse.self, from: TestData.apiJSON)
        let second = response.todos[1]

        XCTAssertEqual(second.id, 2)
        XCTAssertEqual(second.todo, "Clean house")
        XCTAssertTrue(second.completed)
    }

    func test_todoAPIResponse_invalidJSON_throwsError() {
        let badData = "not json".data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(TodoAPIResponse.self, from: badData))
    }

    func test_todoAPIResponse_missingField_throwsError() {
        let incomplete = """
        {"todos": [{"id": 1, "todo": "Test"}]}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(TodoAPIResponse.self, from: incomplete))
    }

    // MARK: - Hashable (критично для Diffable Data Source)

    /// Два объекта с одинаковым id — одна и та же задача, даже если поля отличаются.
    /// Diffable DS использует это для обнаружения обновлений, а не дублей.
    func test_todoItem_sameId_isEqual() {
        let original = TestData.makeTodo(id: 1, title: "Оригинал")
        let updated  = TestData.makeTodo(id: 1, title: "Обновлённое название")

        XCTAssertEqual(original, updated)
    }

    func test_todoItem_differentId_isNotEqual() {
        let first  = TestData.makeTodo(id: 1, title: "Задача 1")
        let second = TestData.makeTodo(id: 2, title: "Задача 1")

        XCTAssertNotEqual(first, second)
    }

    func test_todoItem_hashConsistentWithEquality() {
        let item1 = TestData.makeTodo(id: 5, title: "A")
        let item2 = TestData.makeTodo(id: 5, title: "B")

        // Равные объекты обязаны иметь одинаковый хэш
        XCTAssertEqual(item1.hashValue, item2.hashValue)
    }

    func test_todoItem_usableInSet_deduplicatesByID() {
        let item1 = TestData.makeTodo(id: 10, title: "Первая версия", completed: false)
        let item2 = TestData.makeTodo(id: 10, title: "Вторая версия", completed: true)

        let set = Set([item1, item2])

        // Set должен содержать только одну запись — дубль по id не добавился
        XCTAssertEqual(set.count, 1)
    }
}
