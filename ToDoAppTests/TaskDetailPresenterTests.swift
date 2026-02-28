import XCTest
@testable import ToDoApp

final class TaskDetailPresenterTests: XCTestCase {

    private var presenter: TaskDetailPresenter!
    private var mockView: MockTaskDetailView!
    private var mockInteractor: MockTaskDetailInteractor!
    private var mockRouter: MockTaskDetailRouter!
    private var mockDelegate: MockTaskDetailModuleDelegate!

    override func setUp() {
        super.setUp()
        presenter = TaskDetailPresenter()
        mockView = MockTaskDetailView()
        mockInteractor = MockTaskDetailInteractor()
        mockRouter = MockTaskDetailRouter()
        mockDelegate = MockTaskDetailModuleDelegate()

        presenter.view = mockView
        presenter.interactor = mockInteractor
        presenter.router = mockRouter
        presenter.delegate = mockDelegate
    }

    override func tearDown() {
        presenter = nil
        mockView = nil
        mockInteractor = nil
        mockRouter = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - viewDidLoad

    func test_viewDidLoad_withExistingTodo_showsTodoOnView() {
        let todo = TestData.makeTodo(id: 5, title: "Existing")
        mockInteractor.todo = todo

        presenter.viewDidLoad()

        XCTAssertTrue(mockView.showTodoCalled)
        XCTAssertEqual(mockView.showTodoReceivedTodo?.id, 5)
        XCTAssertEqual(mockView.showTodoReceivedTodo?.title, "Existing")
    }

    func test_viewDidLoad_withNilTodo_doesNotShowTodo() {
        mockInteractor.todo = nil

        presenter.viewDidLoad()

        XCTAssertFalse(mockView.showTodoCalled)
    }

    // MARK: - saveTodo

    func test_saveTodo_withValidTitle_callsInteractor() {
        presenter.saveTodo(title: "Новая задача", description: "Описание")

        XCTAssertTrue(mockInteractor.saveTodoCalled)
        XCTAssertEqual(mockInteractor.saveTodoReceivedTitle, "Новая задача")
        XCTAssertEqual(mockInteractor.saveTodoReceivedDescription, "Описание")
    }

    func test_saveTodo_withEmptyTitle_showsError() {
        presenter.saveTodo(title: "", description: "Описание")

        XCTAssertFalse(mockInteractor.saveTodoCalled)
        XCTAssertTrue(mockView.showErrorCalled)
        XCTAssertEqual(mockView.showErrorReceivedMessage, "Название не может быть пустым")
    }

    func test_saveTodo_withWhitespaceOnlyTitle_showsError() {
        presenter.saveTodo(title: "   \n  ", description: "Описание")

        XCTAssertFalse(mockInteractor.saveTodoCalled)
        XCTAssertTrue(mockView.showErrorCalled)
    }

    func test_saveTodo_withEmptyDescription_callsInteractor() {
        presenter.saveTodo(title: "Задача", description: "")

        XCTAssertTrue(mockInteractor.saveTodoCalled)
        XCTAssertEqual(mockInteractor.saveTodoReceivedDescription, "")
    }

    // MARK: - goBack

    func test_goBack_callsRouter() {
        presenter.goBack()

        XCTAssertTrue(mockRouter.goBackCalled)
    }

    // MARK: - Interactor Output

    func test_didSaveTodo_notifiesDelegateAndView() {
        presenter.didSaveTodo()

        XCTAssertTrue(mockDelegate.didSaveTaskCalled)
        XCTAssertTrue(mockView.taskSavedCalled)
    }

    func test_didFailWithError_showsErrorOnView() {
        presenter.didFailWithError("Ошибка базы данных")

        XCTAssertTrue(mockView.showErrorCalled)
        XCTAssertEqual(mockView.showErrorReceivedMessage, "Ошибка базы данных")
    }

    func test_didLoadTodo_showsTodoOnView() {
        let todo = TestData.makeTodo(id: 10, title: "Loaded")

        presenter.didLoadTodo(todo)

        XCTAssertTrue(mockView.showTodoCalled)
        XCTAssertEqual(mockView.showTodoReceivedTodo?.id, 10)
    }
}
