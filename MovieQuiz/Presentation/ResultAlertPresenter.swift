import UIKit

final class ResultAlertPresenter {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func show(_ model: ResultAlertModel) {
        if #available(iOS 26.0, *) {
            viewController?.present(ResultAlertViewController(model: model), animated: true)
            return
        }
        let alert = UIAlertController(title: model.title, message: model.message, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .light
        alert.addAction(UIAlertAction(title: model.buttonText, style: .default) { _ in
            model.completion()
        })
        viewController?.present(alert, animated: true)
    }
}
