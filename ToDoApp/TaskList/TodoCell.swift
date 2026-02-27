import UIKit

/// Ячейка задачи в главном списке.
final class TodoCell: UITableViewCell {

    static let identifier = "TodoCell"

    /// Замыкание вызывается при нажатии на кнопку-чекбокс — ViewController передаёт его в Presenter
    var onToggle: (() -> Void)?

    // MARK: - UI Elements

    private let checkButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Показывает описание задачи, максимум 2 строки.
    /// Если описание пустое — отображает текст задачи (дублирует title).
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        // SF Pro Text Regular 12 — iOS автоматически использует SF Pro Text для размеров < 20pt
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Собственная линия-разделитель: стандартный separatorStyle = .none,
    /// чтобы управлять отступами и цветом вручную
    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 77/255, green: 85/255, blue: 94/255, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .black
        selectionStyle = .none

        contentView.addSubview(checkButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(separatorLine)

        NSLayoutConstraint.activate([
            checkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            checkButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            checkButton.widthAnchor.constraint(equalToConstant: 24),
            checkButton.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: checkButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            dateLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 6),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            separatorLine.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)
    }

    @objc private func checkTapped() {
        onToggle?()
    }

    // MARK: - Configure

    /// Заполняет ячейку данными задачи.
    /// При выполненной задаче — зачёркивает title и делает текст серым.
    func configure(with todo: TodoItem) {
        let textColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)

        // Если описание пустое (API-задачи) — показываем текст задачи вместо него
        descriptionLabel.text = todo.descriptionText.isEmpty ? todo.title : todo.descriptionText

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        dateLabel.text = formatter.string(from: todo.createdDate)

        updateCheckButton(isCompleted: todo.isCompleted)

        if todo.isCompleted {
            // Зачёркиваем текст и делаем его серым, чтобы визуально отделить выполненные задачи
            titleLabel.attributedText = NSAttributedString(
                string: todo.title,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.gray
                ]
            )
            descriptionLabel.textColor = UIColor.gray.withAlphaComponent(0.6)
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = todo.title
            titleLabel.textColor = textColor
            descriptionLabel.textColor = textColor
        }
    }

    // MARK: - Private

    private func updateCheckButton(isCompleted: Bool) {
        checkButton.setImage(drawCheckmark(isCompleted: isCompleted), for: .normal)
    }

    /// Выполнено — иконка «check» из Assets (24×24).
    /// Не выполнено — рисуем контурный круг rgba(77, 85, 94, 1) программно.
    private func drawCheckmark(isCompleted: Bool) -> UIImage {
        if isCompleted, let asset = UIImage(named: "check") {
            return asset
        }

        // Контурный круг для невыполненной задачи
        let size = CGSize(width: 24, height: 24)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            UIColor(red: 77/255, green: 85/255, blue: 94/255, alpha: 1).setStroke()
            ctx.cgContext.setLineWidth(1.5)
            ctx.cgContext.strokeEllipse(in: rect)
        }
    }
}
