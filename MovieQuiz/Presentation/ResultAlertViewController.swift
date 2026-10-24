import UIKit

// Keeps the Figma alert appearance on systems whose standard alerts use Liquid Glass.
final class ResultAlertViewController: UIViewController {
    private let model: ResultAlertModel
    private let titleLabel = UILabel()

    init(model: ResultAlertModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(model:)")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.accessibilityViewIsModal = true

        let panel = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        panel.contentView.backgroundColor = UIColor(white: 242.0 / 255.0, alpha: 0.8)
        panel.layer.cornerRadius = 14
        panel.clipsToBounds = true

        titleLabel.attributedText = formattedText(model.title, size: 17, weight: .semibold, lineHeight: 22, spacing: -0.41)
        titleLabel.accessibilityTraits = .header
        titleLabel.numberOfLines = 0

        let messageLabel = UILabel()
        messageLabel.attributedText = formattedText(model.message, size: 13, weight: .regular, lineHeight: 18, spacing: -0.08)
        messageLabel.numberOfLines = 0
        messageLabel.accessibilityIdentifier = "roundResultMessage"

        let content = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        content.axis = .vertical
        content.spacing = 2
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let separator = UIView()
        separator.backgroundColor = UIColor(white: 0.24, alpha: 0.29)

        let button = UIButton(type: .system)
        button.setTitle(model.buttonText, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(UIColor(red: 0, green: 122.0 / 255.0, blue: 1, alpha: 1), for: .normal)
        button.addTarget(self, action: #selector(restartTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [content, separator, button])
        stack.axis = .vertical
        view.addSubview(panel)
        panel.contentView.addSubview(stack)
        panel.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            panel.widthAnchor.constraint(equalToConstant: 270),
            panel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            panel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: panel.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: panel.contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: panel.contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    private func formattedText(_ text: String, size: CGFloat, weight: UIFont.Weight, lineHeight: CGFloat, spacing: CGFloat) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        return NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle,
            .kern: spacing
        ])
    }

    @objc private func restartTapped() {
        dismiss(animated: true, completion: model.completion)
    }
}
