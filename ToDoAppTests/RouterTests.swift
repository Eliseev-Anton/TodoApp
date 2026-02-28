import XCTest
@testable import ToDoApp

final class RouterTests: XCTestCase {

    // MARK: - TaskListRouter

    func test_taskListRouter_createModule_returnsNavigationController() {
        let nav = TaskListRouter.createModule()

        XCTAssertNotNil(nav)
        XCTAssertTrue(nav is UINavigationController)
    }

    func test_taskListRouter_createModule_rootIsTaskListViewController() {
        let nav = TaskListRouter.createModule()
        let root = nav.viewControllers.first

        XCTAssertTrue(root is TaskListViewController)
    }

    func test_taskListRouter_createModule_presenterIsConnected() {
        let nav = TaskListRouter.createModule()
        let root = nav.viewControllers.first as? TaskListViewController

        XCTAssertNotNil(root?.presenter)
    }

    func test_taskListRouter_createModule_viperChainIsComplete() {
        let nav = TaskListRouter.createModule()
        let view = nav.viewControllers.first as! TaskListViewController
        let presenter = view.presenter as! TaskListPresenter

        XCTAssertNotNil(presenter.view)
        XCTAssertNotNil(presenter.interactor)
        XCTAssertNotNil(presenter.router)

        let interactor = presenter.interactor as! TaskListInteractor
        XCTAssertNotNil(interactor.presenter)
    }

    // MARK: - TaskDetailRouter

    func test_taskDetailRouter_createModule_returnsViewController() {
        let vc = TaskDetailRouter.createModule(with: nil, delegate: nil)

        XCTAssertTrue(vc is TaskDetailViewController)
    }

    func test_taskDetailRouter_createModule_withTodo_setsInteractorTodo() {
        let todo = TestData.makeTodo(id: 99, title: "Router Test")
        let vc = TaskDetailRouter.createModule(with: todo, delegate: nil) as! TaskDetailViewController
        let presenter = vc.presenter as! TaskDetailPresenter
        let interactor = presenter.interactor as! TaskDetailInteractor

        XCTAssertNotNil(interactor.todo)
        XCTAssertEqual(interactor.todo?.id, 99)
    }

    func test_taskDetailRouter_createModule_withNilTodo_interactorTodoIsNil() {
        let vc = TaskDetailRouter.createModule(with: nil, delegate: nil) as! TaskDetailViewController
        let presenter = vc.presenter as! TaskDetailPresenter
        let interactor = presenter.interactor as! TaskDetailInteractor

        XCTAssertNil(interactor.todo)
    }

    func test_taskDetailRouter_createModule_delegateIsSet() {
        let mockDelegate = MockTaskDetailModuleDelegate()
        let vc = TaskDetailRouter.createModule(with: nil, delegate: mockDelegate) as! TaskDetailViewController
        let presenter = vc.presenter as! TaskDetailPresenter

        XCTAssertNotNil(presenter.delegate)
    }

    func test_taskDetailRouter_createModule_viperChainIsComplete() {
        let vc = TaskDetailRouter.createModule(with: nil, delegate: nil) as! TaskDetailViewController
        let presenter = vc.presenter as! TaskDetailPresenter

        XCTAssertNotNil(presenter.view)
        XCTAssertNotNil(presenter.interactor)
        XCTAssertNotNil(presenter.router)

        let interactor = presenter.interactor as! TaskDetailInteractor
        XCTAssertNotNil(interactor.presenter)
    }
}
