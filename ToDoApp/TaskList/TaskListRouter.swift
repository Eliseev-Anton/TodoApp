import UIKit

/// Отвечает за сборку VIPER-модуля списка задач и навигацию внутри него.
///
final class TaskListRouter: TaskListRouterProtocol {

    /// weak — чтобы избежать retain-цикла
    weak var viewController: UIViewController?

    /// Точка входа в модуль — вызывается из SceneDelegate при старте приложения.
    /// Создаёт все компоненты, связывает их между собой и возвращает готовый стек навигации.
    static func createModule() -> UINavigationController {
        let view = TaskListViewController()
        let presenter = TaskListPresenter()
        let interactor = TaskListInteractor()
        let router = TaskListRouter()

        // Двусторонние связи через протоколы
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter
        router.viewController = view

        let nav = UINavigationController(rootViewController: view)
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }

}
