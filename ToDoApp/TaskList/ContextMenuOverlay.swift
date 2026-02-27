import UIKit

/// Кастомное контекстное меню, появляющееся при долгом нажатии на задачу.
///
/// Добавляется напрямую в window, чтобы перекрывать NavigationBar и BottomBar.
final class ContextMenuOverlay: UIView {

    var onEdit: (() -> Void)?
    var onShare: (() -> Void)?
    var onDelete: (() -> Void)?

    private let todo: TodoItem
    /// Frame выбранной ячейки в координатах window — меню позиционируется над ней
    private let sourceFrame: CGRect

    // MARK: - UI Elements

    private let blurView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let dimmingView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 4/255, green: 4/255, blue: 4/255, alpha: 0.5)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let previewCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 39/255, green: 39/255, blue: 41/255, alpha: 1)
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let previewTitle: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let previewDescription: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let previewDate: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let actionsContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 237/255, green: 237/255, blue: 237/255, alpha: 0.8)
        v.layer.cornerRadius = 14
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Init

    init(todo: TodoItem, sourceFrame: CGRect) {
        self.todo = todo
        self.sourceFrame = sourceFrame
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(blurView)
        addSubview(dimmingView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            dimmingView.topAnchor.constraint(equalTo: topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Превью-карточка
        addSubview(previewCard)
        previewCard.addSubview(previewTitle)
        previewCard.addSubview(previewDescription)
        previewCard.addSubview(previewDate)

        // Карточка выравнивается по позиции ячейки на экране.
        // Зажимаем сверху (60pt — safe area + навбар) и снизу (чтобы панель действий не ушла за край).
        let screenH = UIScreen.main.bounds.height
        let cardH: CGFloat = 106
        let actionsH: CGFloat = 132
        let gap: CGFloat = 8
        let minTop: CGFloat = 60
        let maxTop: CGFloat = screenH - 60 - cardH - gap - actionsH
        let cardTop = min(max(sourceFrame.minY, minTop), maxTop)

        NSLayoutConstraint.activate([
            previewCard.centerXAnchor.constraint(equalTo: centerXAnchor),
            previewCard.topAnchor.constraint(equalTo: topAnchor, constant: cardTop),
            previewCard.widthAnchor.constraint(equalToConstant: 320),
            previewCard.heightAnchor.constraint(equalToConstant: 106),

            previewTitle.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 12),
            previewTitle.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 16),
            previewTitle.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -16),

            previewDescription.topAnchor.constraint(equalTo: previewTitle.bottomAnchor, constant: 6),
            previewDescription.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 16),
            previewDescription.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -16),

            previewDate.topAnchor.constraint(equalTo: previewDescription.bottomAnchor, constant: 6),
            previewDate.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 16),
            previewDate.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -16),
        ])

        previewTitle.text = todo.title
        previewDescription.text = todo.descriptionText.isEmpty ? todo.title : todo.descriptionText
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        previewDate.text = formatter.string(from: todo.createdDate)

        // Панель действий под карточкой
        addSubview(actionsContainer)

        let buttonHeight: CGFloat = 132.0 / 3.0

        let editRow  = makeActionRow(title: "Редактировать", imageName: "edit",   color: .black,  action: #selector(editTapped))
        let shareRow = makeActionRow(title: "Поделиться",    imageName: "export",  color: .black,  action: #selector(shareTapped))
        let deleteRow = makeActionRow(title: "Удалить",      imageName: "trash",   color: .red,    action: #selector(deleteTapped))
        let sep1 = makeSeparator()
        let sep2 = makeSeparator()

        actionsContainer.addSubview(editRow)
        actionsContainer.addSubview(sep1)
        actionsContainer.addSubview(shareRow)
        actionsContainer.addSubview(sep2)
        actionsContainer.addSubview(deleteRow)

        NSLayoutConstraint.activate([
            actionsContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionsContainer.topAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: 8),
            actionsContainer.widthAnchor.constraint(equalToConstant: 254),
            actionsContainer.heightAnchor.constraint(equalToConstant: 132),

            editRow.topAnchor.constraint(equalTo: actionsContainer.topAnchor),
            editRow.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            editRow.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            editRow.heightAnchor.constraint(equalToConstant: buttonHeight),

            sep1.topAnchor.constraint(equalTo: editRow.bottomAnchor),
            sep1.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            sep1.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            sep1.heightAnchor.constraint(equalToConstant: 0.5),

            shareRow.topAnchor.constraint(equalTo: sep1.bottomAnchor),
            shareRow.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            shareRow.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            shareRow.heightAnchor.constraint(equalToConstant: buttonHeight),

            sep2.topAnchor.constraint(equalTo: shareRow.bottomAnchor),
            sep2.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            sep2.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            sep2.heightAnchor.constraint(equalToConstant: 0.5),

            deleteRow.topAnchor.constraint(equalTo: sep2.bottomAnchor),
            deleteRow.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            deleteRow.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            deleteRow.bottomAnchor.constraint(equalTo: actionsContainer.bottomAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        dimmingView.addGestureRecognizer(tap)

        alpha = 0
        previewCard.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        actionsContainer.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
    }

    private func makeActionRow(title: String, imageName: String, color: UIColor, action: Selector) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = color
        label.translatesAutoresizingMaskIntoConstraints = false

        let iv = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate))
        iv.tintColor = color
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false

        // Прозрачная кнопка поверх — принимает тапы без какого-либо фона
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: action, for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        container.addSubview(iv)
        container.addSubview(btn)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            iv.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            iv.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 20),
            iv.heightAnchor.constraint(equalToConstant: 20),

            btn.topAnchor.constraint(equalTo: container.topAnchor),
            btn.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            btn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    private func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    // MARK: - Animations

    func animateIn() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.previewCard.transform = .identity
            self.actionsContainer.transform = .identity
        }
    }

    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.alpha = 0
            self.previewCard.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.actionsContainer.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    // MARK: - Actions

    @objc private func dismiss() { animateOut() }

    @objc private func editTapped()  { animateOut { [weak self] in self?.onEdit?() } }
    @objc private func shareTapped() { animateOut { [weak self] in self?.onShare?() } }
    @objc private func deleteTapped() { animateOut { [weak self] in self?.onDelete?() } }
}

