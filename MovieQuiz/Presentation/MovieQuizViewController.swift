import UIKit

final class MovieQuizViewController: UIViewController {
    private struct Movie {
        let title: String
        let rating: Double
    }

    private let movies = [
        Movie(title: "The Room", rating: 3.7),
        Movie(title: "The Dark Knight", rating: 9.0),
        Movie(title: "Kill Bill", rating: 8.1),
        Movie(title: "The Avengers", rating: 8.0),
        Movie(title: "Deadpool", rating: 8.0),
        Movie(title: "The Green Knight", rating: 6.6),
        Movie(title: "Old", rating: 5.8),
        Movie(title: "The Ice Age Adventures of Buck Wild", rating: 4.3),
        Movie(title: "Tesla", rating: 5.1),
        Movie(title: "Vivarium", rating: 5.8)
    ]

    private let ratingThreshold = 6.0
    private var currentMovieIndex = 0
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

        view.backgroundColor = UIColor(red: 0.102, green: 0.106, blue: 0.125, alpha: 1)
        configureLabels()
        configurePosterImageView()
        configureButtons()
        addSubviews()
        configureConstraints()
        updateQuestion()
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
        questionTitleLabel.font = .systemFont(ofSize: 20, weight: .regular)
        questionTitleLabel.textColor = .white

        progressLabel.font = .systemFont(ofSize: 20, weight: .regular)
        progressLabel.textColor = .white
        progressLabel.textAlignment = .right

        questionLabel.font = .systemFont(ofSize: 20, weight: .bold)
        questionLabel.textColor = .white
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0
    }

    private func configurePosterImageView() {
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 16
        posterImageView.layer.borderWidth = 5
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
        button.setTitleColor(UIColor(red: 0.102, green: 0.106, blue: 0.125, alpha: 1), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        button.backgroundColor = .white
        button.layer.cornerRadius = 14
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

        NSLayoutConstraint.activate([
            questionTitleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            questionTitleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 15),
            questionTitleLabel.heightAnchor.constraint(equalToConstant: 24),

            progressLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            progressLabel.centerYAnchor.constraint(equalTo: questionTitleLabel.centerYAnchor),

            posterImageView.topAnchor.constraint(equalTo: questionTitleLabel.bottomAnchor, constant: 15),
            posterImageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            posterImageView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            posterImageView.heightAnchor.constraint(equalTo: posterImageView.widthAnchor, multiplier: 1.5),

            questionLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 34),
            questionLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),

            noButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            noButton.trailingAnchor.constraint(equalTo: yesButton.leadingAnchor, constant: -16),
            yesButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            noButton.widthAnchor.constraint(equalTo: yesButton.widthAnchor),
            noButton.heightAnchor.constraint(equalToConstant: 60),
            yesButton.heightAnchor.constraint(equalTo: noButton.heightAnchor),
            noButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            yesButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    private func updateQuestion() {
        let movie = movies[currentMovieIndex]
        progressLabel.text = "\(currentMovieIndex + 1)/\(movies.count)"
        questionLabel.text = "Рейтинг этого фильма больше чем \(Int(ratingThreshold))?"
        posterImageView.image = UIImage(named: movie.title)
        posterImageView.layer.borderColor = UIColor.clear.cgColor
        noButton.isEnabled = true
        yesButton.isEnabled = true
    }

    private func handleAnswer(isYes: Bool) {
        guard !isAnswering else { return }
        isAnswering = true
        noButton.isEnabled = false
        yesButton.isEnabled = false

        let movie = movies[currentMovieIndex]
        let correctAnswerIsYes = movie.rating > ratingThreshold
        let isCorrect = isYes == correctAnswerIsYes

        if isCorrect {
            correctAnswerCount += 1
            posterImageView.layer.borderColor = UIColor(red: 0.36, green: 0.72, blue: 0.54, alpha: 1).cgColor
        } else {
            posterImageView.layer.borderColor = UIColor(red: 0.91, green: 0.35, blue: 0.39, alpha: 1).cgColor
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.showNextQuestion()
        }
    }

    private func showNextQuestion() {
        let nextMovieIndex = currentMovieIndex + 1
        guard nextMovieIndex < movies.count else {
            showRoundEndAlert()
            return
        }

        currentMovieIndex = nextMovieIndex
        isAnswering = false
        updateQuestion()
    }

    private func showRoundEndAlert() {
        let alert = UIAlertController(
            title: "Раунд окончен",
            message: "Ваш результат: \(correctAnswerCount) из \(movies.count)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Сыграть ещё раз", style: .default) { [weak self] _ in
            self?.startNewRound()
        })
        present(alert, animated: true)
    }

    private func startNewRound() {
        currentMovieIndex = 0
        correctAnswerCount = 0
        isAnswering = false
        updateQuestion()
    }
}
