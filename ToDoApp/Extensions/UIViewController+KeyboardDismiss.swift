import UIKit

extension UIViewController {

    /// Добавляет тап-жест на view контроллера для скрытия клавиатуры.
    ///
    /// `cancelsTouchesInView = false` — жест не перехватывает тапы,
    /// поэтому нажатия на ячейки таблицы, кнопки и другие интерактивные элементы
    /// продолжают работать в штатном режиме.
    func setupKeyboardDismissOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
