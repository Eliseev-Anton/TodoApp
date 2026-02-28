import UIKit
@testable import ToDoApp

/// Мок View списка задач — запоминает все вызовы, чтобы Presenter-тесты могли проверить,
/// какие методы были вызваны и с какими аргументами.
final class MockTaskListView: TaskListViewProtocol {

    var presenter: TaskListPresenterProtocol?

    // Счётчики и захваченные значения
    var showTodosCalled = false
    var showTodosReceivedTodos: [TodoItem] = []

    var showErrorCalled = false
    var showErrorReceivedMessage: String?

    func showTodos(_ todos: [TodoItem]) {
        showTodosCalled = true
        showTodosReceivedTodos = todos
    }

    func showError(_ message: String) {
        showErrorCalled = true
        showErrorReceivedMessage = message
    }
}
