import UIKit

final class MovieQuizViewController: UIViewController {
    private let questionFactory: QuestionFactoryProtocol = QuestionFactory()
    private let statisticService: StatisticServiceProtocol = StatisticService()
    private lazy var resultAlertPresenter = ResultAlertPresenter(viewController: self)
    private var questions: [QuizQuestion] = []
    private let ypBlack = UIColor(red: 26.0 / 255.0, green: 27.0 / 255.0, blue: 34.0 / 255.0, alpha: 1)
    private let ypGreen = UIColor(red: 96.0 / 255.0, green: 194.0 / 255.0, blue: 142.0 / 255.0, alpha: 1)
    private let ypRed = UIColor(red: 245.0 / 255.0, green: 107.0 / 255.0, blue: 108.0 / 255.0, alpha: 1)
    private var currentQuestionIndex = 0
    private var correctAnswerCount = 0
    private var isAnswering = false

    private let questionTitleLabel = UILabel()
    private let progressLabel = UILabel()
    private let posterImageView = UIImageView()
    private let questionLabel = UILabel()
    private let noButton = UIButton(type: .system)
    private let yesButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ypBlack
        configureLabels()
        configurePosterImageView()
        configureButtons()
        addSubviews()
        configureConstraints()
        startNewRound()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    @objc private func yesButtonTapped() {
        handleAnswer(isYes: true)
    }

    @objc private func noButtonTapped() {
        handleAnswer(isYes: false)
    }

    private func configureLabels() {
        questionTitleLabel.text = "Вопрос:"
        questionTitleLabel.font = UIFont(name: "YSDisplay-Medium", size: 20) ?? .systemFont(ofSize: 20, weight: .regular)
        questionTitleLabel.textColor = .white

        progressLabel.font = UIFont(name: "YSDisplay-Medium", size: 20) ?? .systemFont(ofSize: 20, weight: .regular)
        progressLabel.textColor = .white
        progressLabel.textAlignment = .right
        progressLabel.accessibilityIdentifier = "questionProgress"

        questionLabel.font = UIFont(name: "YSDisplay-Bold", size: 23) ?? .systemFont(ofSize: 23, weight: .bold)
        questionLabel.textColor = .white
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 2
        questionLabel.lineBreakMode = .byWordWrapping
        questionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        questionLabel.accessibilityIdentifier = "questionText"
    }

    private func configurePosterImageView() {
        posterImageView.contentMode = .scaleAspectFit
        posterImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 20
        posterImageView.layer.borderWidth = 8
        posterImageView.layer.borderColor = UIColor.clear.cgColor
        posterImageView.accessibilityIdentifier = "moviePoster"
    }

    private func configureButtons() {
        configureButton(noButton, title: "Нет")
        configureButton(yesButton, title: "Да")

        noButton.addTarget(self, action: #selector(noButtonTapped), for: .touchUpInside)
        yesButton.addTarget(self, action: #selector(yesButtonTapped), for: .touchUpInside)
    }

    private func configureButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(ypBlack, for: .normal)
        button.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20) ?? .systemFont(ofSize: 20, weight: .semibold)
        button.backgroundColor = .white
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.accessibilityIdentifier = title == "Да" ? "yesButton" : "noButton"
    }

    private func addSubviews() {
        [questionTitleLabel, progressLabel, posterImageView, questionLabel, noButton, yesButton]
            .forEach { view.addSubview($0) }
    }

    private func configureConstraints() {
        [questionTitleLabel, progressLabel, posterImageView, questionLabel, noButton, yesButton]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let safeArea = view.safeAreaLayoutGuide
        let posterAspectRatio = posterImageView.heightAnchor.constraint(equalTo: posterImageView.widthAnchor, multiplier: 1.5)
        posterAspectRatio.priority = .defaultHigh

        NSLayoutConstraint.activate([
            questionTitleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            questionTitleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            questionTitleLabel.heightAnchor.constraint(equalToConstant: 24),

            progressLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            progressLabel.centerYAnchor.constraint(equalTo: questionTitleLabel.centerYAnchor),

            posterImageView.topAnchor.constraint(equalTo: questionTitleLabel.bottomAnchor, constant: 15),
            posterImageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            posterImageView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            posterAspectRatio,

            questionLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 34),
            questionLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            questionLabel.bottomAnchor.constraint(lessThanOrEqualTo: noButton.topAnchor, constant: -20),

            noButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            noButton.trailingAnchor.constraint(equalTo: yesButton.leadingAnchor, constant: -20),
            yesButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            noButton.widthAnchor.constraint(equalTo: yesButton.widthAnchor),
            noButton.heightAnchor.constraint(equalToConstant: 60),
            yesButton.heightAnchor.constraint(equalTo: noButton.heightAnchor),
            noButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            yesButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    private func updateQuestion() {
        guard let question = questions[safe: currentQuestionIndex] else { return }
        progressLabel.text = "\(currentQuestionIndex + 1)/\(questions.count)"
        questionLabel.text = question.text
        posterImageView.image = UIImage(named: question.imageName)
        posterImageView.layer.borderColor = UIColor.clear.cgColor
        noButton.isEnabled = true
        yesButton.isEnabled = true
    }

    private func handleAnswer(isYes: Bool) {
        guard !isAnswering, let question = questions[safe: currentQuestionIndex] else { return }
        isAnswering = true
        noButton.isEnabled = false
        yesButton.isEnabled = false

        let isCorrect = isYes == question.correctAnswer

        if isCorrect {
            correctAnswerCount += 1
            posterImageView.layer.borderColor = ypGreen.cgColor
        } else {
            posterImageView.layer.borderColor = ypRed.cgColor
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.showNextQuestion()
        }
    }

    private func showNextQuestion() {
        let nextQuestionIndex = currentQuestionIndex + 1
        guard nextQuestionIndex < questions.count else {
            showRoundEndAlert()
            return
        }

        currentQuestionIndex = nextQuestionIndex
        isAnswering = false
        updateQuestion()
    }

    private func showRoundEndAlert() {
        statisticService.store(correct: correctAnswerCount, total: questions.count)
        let model = ResultAlertModel(
            correctAnswers: correctAnswerCount,
            questionsCount: questions.count,
            statistics: statisticService
        ) { [weak self] in
            self?.startNewRound()
        }
        resultAlertPresenter.show(model)
    }

    private func startNewRound() {
        questions = questionFactory.makeQuestions()
        currentQuestionIndex = 0
        correctAnswerCount = 0
        isAnswering = false
        updateQuestion()
    }
}
