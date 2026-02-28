import XCTest
@testable import ToDoApp

final class TaskListPresenterTests: XCTestCase {

    private var presenter: TaskListPresenter!
    private var mockView: MockTaskListView!
    private var mockInteractor: MockTaskListInteractor!
    private var mockRouter: MockTaskListRouter!

    override func setUp() {
        super.setUp()
        presenter = TaskListPresenter()
        mockView = MockTaskListView()
        mockInteractor = MockTaskListInteractor()
        mockRouter = MockTaskListRouter()

        presenter.view = mockView
        presenter.interactor = mockInteractor
        presenter.router = mockRouter
    }

    override func tearDown() {
        presenter = nil
        mockView = nil
        mockInteractor = nil
        mockRouter = nil
        super.tearDown()
    }

    // MARK: - viewDidLoad

    func test_viewDidLoad_callsFetchTodos() {
        presenter.viewDidLoad()

        XCTAssertTrue(mockInteractor.fetchTodosCalled)
    }

    // MARK: - didSelectTodo

    func test_didSelectTodo_navigatesToDetailWithTodo() {
        let todo = TestData.makeTodo(id: 42, title: "Selected")

        presenter.didSelectTodo(todo)

        XCTAssertTrue(mockRouter.navigateToDetailCalled)
        XCTAssertEqual(mockRouter.navigateToDetailReceivedTodo?.id, 42)
        XCTAssertEqual(mockRouter.navigateToDetailReceivedTodo?.title, "Selected")
    }

    // MARK: - addNewTodo

    func test_addNewTodo_navigatesToDetailWithNil() {
        presenter.addNewTodo()

        XCTAssertTrue(mockRouter.navigateToDetailCalled)
        XCTAssertTrue(mockRouter.navigateToDetailCalledWithNil)
    }

    // MARK: - deleteTodo

    func test_deleteTodo_callsInteractorWithCorrectId() {
        let todo = TestData.makeTodo(id: 7)

        presenter.deleteTodo(todo)

        XCTAssertTrue(mockInteractor.deleteTodoCalled)
        XCTAssertEqual(mockInteractor.deleteTodoReceivedId, 7)
    }

    // MARK: - toggleTodoCompletion

    func test_toggleTodoCompletion_callsInteractorWithCorrectId() {
        let todo = TestData.makeTodo(id: 15)

        presenter.toggleTodoCompletion(todo)

        XCTAssertTrue(mockInteractor.toggleTodoCompletionCalled)
        XCTAssertEqual(mockInteractor.toggleTodoCompletionReceivedId, 15)
    }

    // MARK: - searchTodos

    func test_searchTodos_callsInteractorWithQuery() {
        presenter.searchTodos(query: "купить")

        XCTAssertTrue(mockInteractor.searchTodosCalled)
        XCTAssertEqual(mockInteractor.searchTodosReceivedQuery, "купить")
    }

    // MARK: - Interactor Output

    func test_didFetchTodos_passesTodosToView() {
        let todos = TestData.makeTodoList(count: 3)

        presenter.didFetchTodos(todos)

        XCTAssertTrue(mockView.showTodosCalled)
        XCTAssertEqual(mockView.showTodosReceivedTodos.count, 3)
    }

    func test_didFailWithError_showsErrorOnView() {
        presenter.didFailWithError("Сеть недоступна")

        XCTAssertTrue(mockView.showErrorCalled)
        XCTAssertEqual(mockView.showErrorReceivedMessage, "Сеть недоступна")
    }

    func test_didUpdateData_refetchesTodosFromInteractor() {
        presenter.didUpdateData()

        XCTAssertTrue(mockInteractor.fetchTodosCalled)
    }
}
