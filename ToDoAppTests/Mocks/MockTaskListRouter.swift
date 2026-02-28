import UIKit
@testable import ToDoApp

final class MockTaskListRouter: TaskListRouterProtocol {

    var navigateToDetailCalled = false
    var navigateToDetailReceivedTodo: TodoItem?
    var navigateToDetailCalledWithNil = false

    static func createModule() -> UINavigationController {
        return UINavigationController()
    }

    func navigateToDetail(from view: TaskListViewProtocol, with todo: TodoItem?) {
        navigateToDetailCalled = true
        navigateToDetailReceivedTodo = todo
        if todo == nil {
            navigateToDetailCalledWithNil = true
        }
    }
}
