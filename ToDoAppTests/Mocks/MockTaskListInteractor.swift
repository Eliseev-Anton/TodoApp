import Foundation
@testable import ToDoApp

final class MockTaskListInteractor: TaskListInteractorInputProtocol {

    weak var presenter: TaskListInteractorOutputProtocol?

    var fetchTodosCalled = false
    var deleteTodoCalled = false
    var deleteTodoReceivedId: Int64?
    var toggleTodoCompletionCalled = false
    var toggleTodoCompletionReceivedId: Int64?
    var searchTodosCalled = false
    var searchTodosReceivedQuery: String?

    func fetchTodos() {
        fetchTodosCalled = true
    }

    func deleteTodo(id: Int64) {
        deleteTodoCalled = true
        deleteTodoReceivedId = id
    }

    func toggleTodoCompletion(id: Int64) {
        toggleTodoCompletionCalled = true
        toggleTodoCompletionReceivedId = id
    }

    func searchTodos(query: String) {
        searchTodosCalled = true
        searchTodosReceivedQuery = query
    }
}
