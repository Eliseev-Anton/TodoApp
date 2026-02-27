import Foundation
import CoreData
import UIKit

/// Единая точка доступа к CoreData-стеку.
///
/// Все операции с базой выполняются в фоновом контексте (backgroundContext),
/// что исключает блокировку главного потока даже при большом объёме задач.
/// viewContext используется только как источник нотификаций через automaticallyMergesChangesFromParent.
final class CoreDataManager {

    static let shared = CoreDataManager()

    private init() {}

    // Контекст главного потока — только для чтения/нотификаций, не для записи
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AppToDo")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // В продакшене здесь стоит предложить пользователю переустановить приложение
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        // Автоматически синхронизируем изменения из фоновых контекстов в viewContext
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    /// Каждый раз создаём новый контекст, чтобы изолировать параллельные операции
    private var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    // MARK: - Fetch

    /// Загружает все задачи из CoreData, отсортированные по дате создания (новые сверху).
    func fetchTodos(completion: @escaping ([TodoItem]) -> Void) {
        let bgContext = backgroundContext
        bgContext.perform {
            let request = NSFetchRequest<TodoItemEntity>(entityName: "TodoItemEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
            do {
                let entities = try bgContext.fetch(request)
                // Дедуплицируем результат: если в базе остались дубли от предыдущих запусков,
                // они не попадут в UI. Порядок сортировки сохраняется через сохранение первого
                // вхождения каждого id (fetched уже отсортирован по createdDate desc).
                var seen = Set<Int64>()
                let items = entities.compactMap { entity -> TodoItem? in
                    let item = self.mapEntityToItem(entity)
                    guard seen.insert(item.id).inserted else { return nil }
                    return item
                }
                DispatchQueue.main.async {
                    completion(items)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }

    // MARK: - Save

    /// Сохраняет одну задачу — используется при создании новой задачи пользователем.
    func saveTodo(_ item: TodoItem, completion: @escaping (Bool) -> Void) {
        let bgContext = backgroundContext
        bgContext.perform {
            let entity = TodoItemEntity(context: bgContext)
            entity.id = item.id
            entity.title = item.title
            entity.descriptionText = item.descriptionText
            entity.createdDate = item.createdDate
            entity.isCompleted = item.isCompleted
            do {
                try bgContext.save()
                DispatchQueue.main.async { completion(true) }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    /// Пакетное сохранение задач с upsert-логикой — вызывается при первом запуске.
    ///
    /// Для каждого item сначала ищем запись с таким же id — если нашли, обновляем,
    /// если нет — создаём новую. Это предотвращает дубли при повторном вызове
    /// (например, при гонке двух параллельных запросов на старте).
    func saveTodos(_ items: [TodoItem], completion: @escaping (Bool) -> Void) {
        let bgContext = backgroundContext
        bgContext.perform {
            // Дедуплицируем входной массив: если API прислал два элемента с одним id,
            // побеждает последний — Dictionary убирает дубли ключей автоматически
            let uniqueItems = items.reduce(into: [Int64: TodoItem]()) { $0[$1.id] = $1 }.values

            for item in uniqueItems {
                // Upsert: ищем существующую запись по id
                let request = NSFetchRequest<TodoItemEntity>(entityName: "TodoItemEntity")
                request.predicate = NSPredicate(format: "id == %lld", item.id)
                request.fetchLimit = 1

                let entity: TodoItemEntity
                if let existing = try? bgContext.fetch(request).first {
                    entity = existing   // обновляем существующую, не создаём дубль
                } else {
                    entity = TodoItemEntity(context: bgContext)   // только если нет записи
                }

                entity.id = item.id
                entity.title = item.title
                entity.descriptionText = item.descriptionText
                entity.createdDate = item.createdDate
                entity.isCompleted = item.isCompleted
            }
            do {
                try bgContext.save()
                DispatchQueue.main.async { completion(true) }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    // MARK: - Update

    /// Обновляет существующую задачу по id.
    /// Ищем по id, а не по objectID, чтобы не тащить CoreData-зависимости в доменный слой.
    func updateTodo(_ item: TodoItem, completion: @escaping (Bool) -> Void) {
        let bgContext = backgroundContext
        bgContext.perform {
            let request = NSFetchRequest<TodoItemEntity>(entityName: "TodoItemEntity")
            request.predicate = NSPredicate(format: "id == %lld", item.id)
            do {
                let results = try bgContext.fetch(request)
                if let entity = results.first {
                    entity.title = item.title
                    entity.descriptionText = item.descriptionText
                    entity.isCompleted = item.isCompleted
                    entity.createdDate = item.createdDate
                    try bgContext.save()
                    DispatchQueue.main.async { completion(true) }
                } else {
                    // Задача могла быть удалена параллельно — возвращаем false без краша
                    DispatchQueue.main.async { completion(false) }
                }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    // MARK: - Delete

    /// Удаляет задачу по id. Если записей с таким id несколько (дубли) — удалит все.
    func deleteTodo(id: Int64, completion: @escaping (Bool) -> Void) {
        let bgContext = backgroundContext
        bgContext.perform {
            let request = NSFetchRequest<TodoItemEntity>(entityName: "TodoItemEntity")
            request.predicate = NSPredicate(format: "id == %lld", id)
            do {
                let results = try bgContext.fetch(request)
                for entity in results {
                    bgContext.delete(entity)
                }
                try bgContext.save()
                DispatchQueue.main.async { completion(true) }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    // MARK: - Toggle completion

    /// Инвертирует статус выполнения задачи прямо в базе без необходимости передавать полный объект.
    func toggleTodoCompletion(id: Int64, completion: @escaping (Bool) -> Void) {
        let bgContext = backgroundContext
        bgContext.perform {
            let request = NSFetchRequest<TodoItemEntity>(entityName: "TodoItemEntity")
            request.predicate = NSPredicate(format: "id == %lld", id)
            do {
                let results = try bgContext.fetch(request)
                if let entity = results.first {
                    entity.isCompleted = !entity.isCompleted
                    try bgContext.save()
                    DispatchQueue.main.async { completion(true) }
                } else {
                    DispatchQueue.main.async { completion(false) }
                }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    // MARK: - Search

    /// Полнотекстовый поиск по названию и описанию задачи.
    /// [cd] — регистронезависимый поиск без учёта диакритических знаков (ё = е и т.п.)
    func searchTodos(query: String, completion: @escaping ([TodoItem]) -> Void) {
        let bgContext = backgroundContext
        bgContext.perform {
            let request = NSFetchRequest<TodoItemEntity>(entityName: "TodoItemEntity")
            request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR descriptionText CONTAINS[cd] %@", query, query)
            request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
            do {
                let entities = try bgContext.fetch(request)
                let items = entities.map { self.mapEntityToItem($0) }
                DispatchQueue.main.async { completion(items) }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }
    }

    // MARK: - Utility

    /// Проверяет, есть ли вообще данные в базе.
    /// Используется при старте приложения: если база пуста — грузим из API.
    func hasData(completion: @escaping (Bool) -> Void) {
        let bgContext = backgroundContext
        bgContext.perform {
            let request = NSFetchRequest<TodoItemEntity>(entityName: "TodoItemEntity")
            // fetchLimit = 1 — не тянем все записи, просто проверяем наличие хотя бы одной
            request.fetchLimit = 1
            do {
                let count = try bgContext.count(for: request)
                DispatchQueue.main.async { completion(count > 0) }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    /// Возвращает следующий свободный id для новой задачи.
    /// Берём максимальный существующий и увеличиваем на 1 — простая стратегия без UUID,
    /// чтобы id новых задач не конфликтовали с загруженными из API (те идут от 1 до N).
    func nextId(completion: @escaping (Int64) -> Void) {
        let bgContext = backgroundContext
        bgContext.perform {
            let request = NSFetchRequest<TodoItemEntity>(entityName: "TodoItemEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
            request.fetchLimit = 1
            do {
                let results = try bgContext.fetch(request)
                let maxId = results.first?.id ?? 0
                DispatchQueue.main.async { completion(maxId + 1) }
            } catch {
                DispatchQueue.main.async { completion(1) }
            }
        }
    }

    // MARK: - Mapping

    /// Преобразует CoreData-сущность в доменную модель.
    /// Все поля — опциональные в CoreData, поэтому используем безопасные дефолты.
    private func mapEntityToItem(_ entity: TodoItemEntity) -> TodoItem {
        return TodoItem(
            id: entity.id,
            title: entity.title ?? "",
            descriptionText: entity.descriptionText ?? "",
            createdDate: entity.createdDate ?? Date(),
            isCompleted: entity.isCompleted
        )
    }
}

