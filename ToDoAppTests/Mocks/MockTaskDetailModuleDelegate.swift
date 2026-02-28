import Foundation
@testable import ToDoApp

final class MockTaskDetailModuleDelegate: TaskDetailModuleDelegate {

    var didSaveTaskCalled = false

    func didSaveTask() {
        didSaveTaskCalled = true
    }
}
