import Foundation
@testable import ToDoApp

final class MockTaskDetailInteractor: TaskDetailInteractorInputProtocol {

    weak var presenter: TaskDetailInteractorOutputProtocol?
    var todo: TodoItem?

    var saveTodoCalled = false
    var saveTodoReceivedTitle: String?
    var saveTodoReceivedDescription: String?

    func saveTodo(title: String, description: String) {
        saveTodoCalled = true
        saveTodoReceivedTitle = title
        saveTodoReceivedDescription = description
    }
}
