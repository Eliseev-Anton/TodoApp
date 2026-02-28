import UIKit
@testable import ToDoApp

final class MockTaskDetailView: TaskDetailViewProtocol {

    var presenter: TaskDetailPresenterProtocol?

    var showTodoCalled = false
    var showTodoReceivedTodo: TodoItem?

    var showErrorCalled = false
    var showErrorReceivedMessage: String?

    var taskSavedCalled = false

    func showTodo(_ todo: TodoItem) {
        showTodoCalled = true
        showTodoReceivedTodo = todo
    }

    func showError(_ message: String) {
        showErrorCalled = true
        showErrorReceivedMessage = message
    }

    func taskSaved() {
        taskSavedCalled = true
    }
}
