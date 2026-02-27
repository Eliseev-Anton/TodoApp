
import Foundation

/// Доменная модель задачи — используется во всех слоях приложения (Presenter, Interactor, View).
struct TodoItem {
    var id: Int64
    /// Краткое название задачи, отображается в ячейке списка
    var title: String
    /// Подробное описание — может быть пустым для задач, загруженных из API
    var descriptionText: String
    /// Дата создания задачи; для API-задач проставляется текущая дата при первой загрузке
    var createdDate: Date
    var isCompleted: Bool
}

/// Идентичность задачи определяется только по id — два объекта с одинаковым id это одна задача.
/// Это критично для Diffable Data Source: при изменении isCompleted снапшот правильно
/// обновит ячейку, а не создаст дубль.
extension TodoItem: Hashable {
    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Корневой объект ответа от dummyjson.com/todos
struct TodoAPIResponse: Decodable {
    let todos: [TodoAPIItem]
}

/// Задача в том виде, в котором её возвращает API.
/// Поля намеренно минимальны — только то, что даёт сервер.
/// При сохранении в CoreData маппируется в TodoItem с заполнением недостающих полей.
struct TodoAPIItem: Decodable {
    let id: Int
    let todo: String
    let completed: Bool
    /// userId нужен API-контрактом, но в приложении не используется
    let userId: Int
}

