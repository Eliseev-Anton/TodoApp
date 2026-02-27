import Foundation

/// Interactor списка задач — единственный компонент, который работает с данными напрямую.
///
/// Логика первого запуска: при старте проверяем CoreData.
/// Если база пуста — загружаем задачи из API и сохраняем в CoreData.
/// При последующих запусках данные берутся только из CoreData.
final class TaskListInteractor: TaskListInteractorInputProtocol {

    weak var presenter: TaskListInteractorOutputProtocol?

    private let coreDataManager = CoreDataManager.shared
    private let networkService = NetworkService.shared

    /// Главная точка входа для загрузки данных.
    /// Все операции с данными выполняются в фоне внутри CoreDataManager.
    func fetchTodos() {
        coreDataManager.hasData { [weak self] hasData in
            guard let self = self else { return }
            if hasData {
                // Повторный запуск — берём из локальной базы
                self.loadFromCoreData()
            } else {
                // Первый запуск — идём в сеть
                self.loadFromAPIAndSave()
            }
        }
    }

    func deleteTodo(id: Int64) {
        coreDataManager.deleteTodo(id: id) { [weak self] success in
            if success {
                // Уведомляем Presenter, что нужно обновить список
                self?.presenter?.didUpdateData()
            } else {
                self?.presenter?.didFailWithError("Не удалось удалить задачу")
            }
        }
    }

    func toggleTodoCompletion(id: Int64) {
        coreDataManager.toggleTodoCompletion(id: id) { [weak self] success in
            if success {
                self?.presenter?.didUpdateData()
            } else {
                self?.presenter?.didFailWithError("Не удалось обновить задачу")
            }
        }
    }

    func searchTodos(query: String) {
        if query.isEmpty {
            // Пустой запрос — показываем все задачи
            loadFromCoreData()
        } else {
            coreDataManager.searchTodos(query: query) { [weak self] todos in
                self?.presenter?.didFetchTodos(todos)
            }
        }
    }

    // MARK: - Private

    private func loadFromCoreData() {
        coreDataManager.fetchTodos { [weak self] todos in
            self?.presenter?.didFetchTodos(todos)
        }
    }

    /// Загружает задачи из API, маппирует в доменные модели и сохраняет в CoreData.
    /// descriptionText оставляем пустым — API его не предоставляет.
    /// createdDate проставляем текущей датой — в API поля нет.
    private func loadFromAPIAndSave() {
        networkService.fetchTodos { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let apiItems):
                let todos = apiItems.map { apiItem -> TodoItem in
                    TodoItem(
                        id: Int64(apiItem.id),
                        title: apiItem.todo,
                        descriptionText: apiItem.todo,
                        createdDate: Date(),
                        isCompleted: apiItem.completed
                    )
                }
                self.coreDataManager.saveTodos(todos) { [weak self] _ in
                    // После сохранения читаем из базы — это источник правды
                    self?.loadFromCoreData()
                }
            case .failure(let error):
                self.presenter?.didFailWithError(error.localizedDescription)
            }
        }
    }
}
