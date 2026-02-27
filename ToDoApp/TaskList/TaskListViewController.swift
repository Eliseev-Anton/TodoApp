import UIKit

/// Главный экран приложения — список задач.
///
/// View в VIPER-архитектуре: не содержит бизнес-логики, только отображение.
///
/// Использует UITableViewDiffableDataSource — снапшоты идемпотентны по id,
/// поэтому двойной вызов showTodos с теми же данными не создаёт дублей.
/// Навигация скрыта — кастомный заголовок и поиск для точного контроля отступов.
final class TaskListViewController: UIViewController, TaskListViewProtocol {

    var presenter: TaskListPresenterProtocol?

    // MARK: - Diffable Data Source

    
    private var dataSource: UITableViewDiffableDataSource<Int, Int64>!

    /// Хранилище задач: ключ — id, значение — объект.
    /// Полностью заменяется при каждом вызове showTodos
    private var itemStore: [Int64: TodoItem] = [:]

    /// Флаг нужен только для поиска: определяет, надо ли при возврате сбрасывать поле.
    /// Сами данные для отображения всегда приходят через showTodos
    private var isSearchActive = false

    // MARK: - UI Elements

    /// Кастомный заголовок вместо large title
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Задачи"
        label.font = .boldSystemFont(ofSize: 34)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Кастомная поисковая строка
    private lazy var searchContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 39/255, green: 39/255, blue: 41/255, alpha: 1)
        v.layer.cornerRadius = 10
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var searchIconView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = UIImage(systemName: "magnifyingglass", withConfiguration: config)
        let iv = UIImageView(image: image)
        iv.tintColor = .gray
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var searchTextField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(
            string: "Поиск",
            attributes: [.foregroundColor: UIColor.gray]
        )
        tf.font = .systemFont(ofSize: 17)
        tf.textColor = .white
        tf.backgroundColor = .clear
        tf.returnKeyType = .search
        tf.delegate = self
        tf.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// Кнопка голосового ввода
    private lazy var micButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        btn.setImage(UIImage(named: "audio"), for: .normal)
        btn.tintColor =  UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        btn.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.register(TodoCell.self, forCellReuseIdentifier: TodoCell.identifier)
        tv.backgroundColor = .black
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 106
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var taskCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 11)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 39/255, green: 39/255, blue: 41/255, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var addButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        btn.setImage(UIImage(systemName: "square.and.pencil", withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        setupKeyboardDismissOnTap()
        presenter?.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Только скрываем навбар — данные обновляются через didSaveTask делегат,
        // а не здесь, чтобы не было двойного запроса при каждом появлении экрана
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Data Source

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, Int64>(
            tableView: tableView
        ) { [weak self] (tableView: UITableView, indexPath: IndexPath, itemID: Int64) -> UITableViewCell in
            guard
                let self,
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: TodoCell.identifier,
                    for: indexPath
                ) as? TodoCell,
                let todo = self.itemStore[itemID]
            else {
                return UITableViewCell()
            }

            cell.configure(with: todo)
            // Захватываем todo из itemStore — он всегда актуален на момент создания ячейки
            cell.onToggle = { [weak self] in
                // Берём свежую версию из стора — isCompleted мог измениться
                guard let current = self?.itemStore[itemID] else { return }
                self?.presenter?.toggleTodoCompletion(current)
            }
            return cell
        }

        // Без анимации при первой загрузке — таблица пуста, нечего анимировать
        dataSource.defaultRowAnimation = UITableView.RowAnimation.fade
    }

    // MARK: - Snapshot

    /// Применяет новый снапшот к таблице.
    /// Diffable DS сравнивает id элементов — одинаковые id не дублируются,
    /// изменённые элементы обновляются через reconfigureItems.
    private func applySnapshot(todos: [TodoItem], animate: Bool = true) {
        // Полностью перезаписываем стор через reduce — безопасен при дублях в массиве,
        // в отличие от Dictionary(uniqueKeysWithValues:) который крашится на дубликатах
        itemStore = todos.reduce(into: [Int64: TodoItem]()) { $0[$1.id] = $1 }

        var snapshot = NSDiffableDataSourceSnapshot<Int, Int64>()
        snapshot.appendSections([0])
        snapshot.appendItems(todos.map(\.id), toSection: 0)

        // iOS 15+: reconfigureItems обновляет содержимое ячейки без пересоздания
        // Для совместимости с iOS 14 используем reloadItems для изменившихся строк
        if #available(iOS 15.0, *) {
            let existingIDs = dataSource.snapshot().itemIdentifiers
            let changedIDs = todos.filter { existingIDs.contains($0.id) }.map(\.id)
            if !changedIDs.isEmpty {
                snapshot.reconfigureItems(changedIDs)
            }
        }

        dataSource.apply(snapshot, animatingDifferences: animate)
        updateCountLabel(count: todos.count)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .black
        overrideUserInterfaceStyle = .dark

        view.addSubview(titleLabel)
        view.addSubview(searchContainer)
        searchContainer.addSubview(searchIconView)
        searchContainer.addSubview(searchTextField)
        searchContainer.addSubview(micButton)
        view.addSubview(tableView)
        view.addSubview(bottomBar)
        bottomBar.addSubview(taskCountLabel)
        bottomBar.addSubview(addButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            searchContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchContainer.heightAnchor.constraint(equalToConstant: 36),

            searchIconView.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 8),
            searchIconView.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIconView.widthAnchor.constraint(equalToConstant: 16),
            searchIconView.heightAnchor.constraint(equalToConstant: 16),

            searchTextField.leadingAnchor.constraint(equalTo: searchIconView.trailingAnchor, constant: 6),
            searchTextField.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -4),
            searchTextField.topAnchor.constraint(equalTo: searchContainer.topAnchor),
            searchTextField.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor),

            micButton.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -8),
            micButton.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 20),
            micButton.heightAnchor.constraint(equalToConstant: 20),

            tableView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 83),

            taskCountLabel.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            taskCountLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 20.5),

            addButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            addButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 6),
            addButton.widthAnchor.constraint(equalToConstant: 44),
            addButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    // MARK: - Helpers

    /// Склоняет слово "задача" по правилам русского языка
    private func updateCountLabel(count: Int) {
        let lastTwo = count % 100
        let lastOne = count % 10
        let word: String
        if lastTwo >= 11 && lastTwo <= 19 {
            word = "Задач"
        } else if lastOne == 1 {
            word = "Задача"
        } else if lastOne >= 2 && lastOne <= 4 {
            word = "Задачи"
        } else {
            word = "Задач"
        }
        taskCountLabel.text = "\(count) \(word)"
    }

    // MARK: - Actions

    @objc private func micTapped() {
        // Фокусируем поле — на клавиатуре появится встроенная кнопка микрофона.
        // Программно запустить диктовку без Speech framework невозможно через публичное API,
        // поэтому используем стандартный механизм iOS: mic-кнопка на системной клавиатуре.
        searchTextField.becomeFirstResponder()
    }

    @objc private func searchTextChanged() {
        let query = searchTextField.text ?? ""
        if query.isEmpty {
            isSearchActive = false
            // Возвращаем полный список — Presenter перечитает из CoreData
            presenter?.viewDidLoad()
        } else {
            isSearchActive = true
            presenter?.searchTodos(query: query)
        }
    }

    // MARK: - TaskListViewProtocol

    func showTodos(_ todos: [TodoItem]) {
        // Первый показ — без анимации, чтобы таблица не "мигала" при старте
        let isFirstLoad = dataSource.snapshot().numberOfItems == 0
        applySnapshot(todos: todos, animate: !isFirstLoad)
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


// MARK: - UITextFieldDelegate

extension TaskListViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


