import UIKit
@testable import ToDoApp

final class MockTaskDetailRouter: TaskDetailRouterProtocol {

    var goBackCalled = false

    static func createModule(with todo: TodoItem?, delegate: TaskDetailModuleDelegate?) -> UIViewController {
        return UIViewController()
    }

    func goBack(from view: TaskDetailViewProtocol) {
        goBackCalled = true
    }
}
