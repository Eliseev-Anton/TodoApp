import Foundation

/// Отвечает за сетевые запросы к внешнему API.
final class NetworkService {

    static let shared = NetworkService()

    private init() {}

    /// Загружает список задач из dummyjson.com.
    /// Вызывается только при первом запуске, когда CoreData ещё пуста.
    /// Декодирование и передача результата выполняются на главном потоке.
    ///
    /// - Parameter completion: замыкание с результатом — массив задач или ошибка
    func fetchTodos(completion: @escaping (Result<[TodoAPIItem], Error>) -> Void) {
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            // Невалидный URL — теоретически невозможно, но обрабатываем явно
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                // Сетевая ошибка: нет интернета, таймаут и т.д.
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                // Сервер ответил, но тело пустое — редкий случай
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No data", code: 0)))
                }
                return
            }

            do {
                let response = try JSONDecoder().decode(TodoAPIResponse.self, from: data)
                DispatchQueue.main.async { completion(.success(response.todos)) }
            } catch {
                // Структура JSON изменилась или пришёл неожиданный формат
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        task.resume()
    }
}

