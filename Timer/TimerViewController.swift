//
//  TimerViewController.swift
//  Timer
//
//  Created by Dima on 17.11.2022.
//

import UIKit

final class TimerViewController: UIViewController {
	private let progressLayer = CAShapeLayer()
	private let timeLabel = UILabel()
	private let resetButton = UIButton()
	private let startPauseButton = UIButton()
	
	private let dateFormatter: DateFormatter = {
		var formatter = DateFormatter()
		formatter.dateFormat = "mm:ss"
		return formatter
	}()
	
	private var timer: Timer?
	
	private var state: State = .initial {
		didSet {
			displayState()
		}
	}
	
	deinit {
		timer?.invalidate()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(onBecomeInactive),
			name: UIApplication.didEnterBackgroundNotification,
			object: nil
		)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(onBecomeActive),
			name: UIApplication.willEnterForegroundNotification,
			object: nil
		)
		
		view.layer.addSublayer(progressLayer)
		view.addSubview(timeLabel)
		view.addSubview(resetButton)
		view.addSubview(startPauseButton)
		
		configure()
		
		displayState()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		layoutProgressLayer()
		layoutTimeLabel()
		layoutButtons()
	}
	
	private func displayState() {
		switch state {
		case .initial:
			configureProgressLayerForInitial()
			configureTimeLabelForInitial()
			configureStartPauseButtonForInitial()
			
		case let .running(initialTime, initialProgress):
			configureProgressLayerForRunning(initialTime: initialTime, initialProgress: initialProgress)
			configureTimeLabelForRunning(initialTime: initialTime, initialProgress: initialProgress)
			configureStartPauseButtonForRunning()
			
		case let .paused(progress):
			configureProgressLayerForPause(progress: progress)
			configureTimeLabelForPause()
			configureStartPauseButtonForPause()

		case .finished:
			configureTimeLabelForPause()
			configureStartPauseButtonForFinish()
		}
	}
	
	// MARK: LAYOUT -
	
	private func layoutProgressLayer() {
		let side = 0.8 * min(view.bounds.width, view.bounds.height)
		progressLayer.frame = CGRect(
			x: (view.bounds.width - side) / 2,
			y: (view.bounds.height - side) / 2,
			width: side,
			height: side
		)
		progressLayer.path = UIBezierPath(ovalIn: progressLayer.bounds).cgPath
	}
	
	private func layoutTimeLabel() {
		timeLabel.frame.size = CGSize(width: view.bounds.width, height: 64)
		timeLabel.center = view.center
	}
	
	private func layoutButtons() {
		let side: CGFloat = 64
		let cornerRadius = side / 2
		let horizontalIndent: CGFloat = 32
		
		resetButton.frame = CGRect(
			x: view.safeAreaInsets.left + horizontalIndent,
			y: view.bounds.height - view.safeAreaInsets.bottom - side,
			width: side,
			height: side
		)
		resetButton.layer.cornerRadius = cornerRadius
		
		startPauseButton.frame = CGRect(
			x: view.bounds.width - view.safeAreaInsets.right - horizontalIndent - side,
			y: view.bounds.height - view.safeAreaInsets.bottom - side,
			width: side,
			height: side
		)
		startPauseButton.layer.cornerRadius = cornerRadius
	}
	
	// MARK: CONFIGURATION -
	
	// MARK: Common Configuration
	
	private func configure() {
		view.backgroundColor = .systemBackground
		
		progressLayer.strokeColor = UIColor.systemGray.cgColor
		progressLayer.fillColor = UIColor.clear.cgColor
		progressLayer.lineWidth = 6
		progressLayer.lineCap = .round
		progressLayer.shadowColor = UIColor.systemGray.cgColor
		progressLayer.shadowRadius = 9
		progressLayer.shadowOpacity = 1
		progressLayer.transform = CATransform3DMakeRotation(-90 / 180 * .pi, 0, 0, 1)
		
		let buttonsFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
		
		resetButton.translatesAutoresizingMaskIntoConstraints = false
		resetButton.backgroundColor = .systemGray2
		resetButton.titleLabel?.font = buttonsFont
		resetButton.setTitle("RESET", for: .normal)
		resetButton.addTarget(self, action: #selector(onTapResetButton), for: .touchUpInside)
		
		startPauseButton.translatesAutoresizingMaskIntoConstraints = false
		startPauseButton.titleLabel?.font = buttonsFont
		startPauseButton.setTitle(Constants.startButtonTitle, for: .normal)
		startPauseButton.addTarget(self, action: #selector(onTapStartPauseButton), for: .touchUpInside)
		
		timeLabel.translatesAutoresizingMaskIntoConstraints = false
		timeLabel.textAlignment = .center
		timeLabel.font = .systemFont(ofSize: 41, weight: .semibold)
	}
	
	// MARK: Progress Layer Configuration
	
	private func configureProgressLayerForInitial() {
		progressLayer.strokeEnd = 1
		progressLayer.removeAllAnimations()
	}
	
	private func configureProgressLayerForRunning(initialTime: TimeInterval, initialProgress: CGFloat) {
		let progressAnimation = CABasicAnimation(keyPath: "strokeEnd")
		let adjustedProgress = calculateAdjustedProgress(initialTime: initialTime, initialProgress: initialProgress)
		progressAnimation.fromValue = 1 - adjustedProgress
		progressAnimation.toValue = 0
		progressAnimation.duration = Constants.duration * (1 - adjustedProgress)
		progressAnimation.delegate = self
		progressLayer.strokeEnd = 0
		progressLayer.add(progressAnimation, forKey: nil)
	}
	
	private func configureProgressLayerForPause(progress: CGFloat) {
		progressLayer.strokeEnd = 1 - progress
		progressLayer.removeAllAnimations()
	}
	
	// MARK: Time Label Configuration
	
	private func configureTimeLabelForInitial() {
		timer?.invalidate()
		
		timeLabel.text = formatTime(from: Constants.duration)
	}
	
	private func configureTimeLabelForRunning(initialTime: TimeInterval, initialProgress: CGFloat) {
		let adjustedProgress = calculateAdjustedProgress(initialTime: initialTime, initialProgress: initialProgress)
		var seconds = Constants.duration * (1 - adjustedProgress)
		
		let timer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
			if seconds <= 0 {
				timer.invalidate()
			}
			
			self?.timeLabel.text = self?.formatTime(from: seconds)
			
			seconds -= 1
		}
		timer.tolerance = 0
		
		RunLoop.current.add(timer, forMode: .common)
		
		timer.fire()
		
		self.timer = timer
	}
	
	private func configureTimeLabelForPause() {
		timer?.invalidate()
	}
	
	// MARK: Buttons Configuration
	
	private func configureStartPauseButtonForInitial() {
		startPauseButton.backgroundColor = Constants.startButtonBackground
		startPauseButton.setTitle(Constants.startButtonTitle, for: .normal)
		startPauseButton.isHidden = false
	}
	
	private func configureStartPauseButtonForRunning() {
		startPauseButton.backgroundColor = .systemRed
		startPauseButton.setTitle("PAUSE", for: .normal)
	}
	
	private func configureStartPauseButtonForPause() {
		startPauseButton.backgroundColor = Constants.startButtonBackground
		startPauseButton.setTitle(Constants.startButtonTitle, for: .normal)
	}
	
	private func configureStartPauseButtonForFinish() {
		startPauseButton.isHidden = true
	}
	
	// MARK: ACTIONS -
	
	@objc private func onTapStartPauseButton() {
		switch state {
		case .initial:
			state = .running(startTime: Date().timeIntervalSince1970, initialProgress: .zero)
			
		case let .running(_, initialProgress):
			let presentationProgress = progressLayer.presentation()?.strokeEnd
			if presentationProgress == nil {
				assertionFailure("Unexpected behavior: `progressLayer.presentation()` shouldn't be nil at `.running` state.")
			}
			state = .paused(progress: 1 - (presentationProgress ?? initialProgress))
			
		case let .paused(initialProgress):
			state = .running(startTime: Date().timeIntervalSince1970, initialProgress: initialProgress)
			
		case .finished:
			assertionFailure("Unexpected behavior: `startPauseButton` should be hidden at `.finished` state.")
		}
	}
	
	@objc private func onTapResetButton() {
		state = .initial
	}
	
	@objc private func onBecomeInactive() {
		timer?.invalidate()
	}
	
	@objc private func onBecomeActive() {
		displayState()
	}
	
	// MARK: HELPERS -
	
	private func calculateAdjustedProgress(initialTime: TimeInterval, initialProgress: CGFloat) -> CGFloat {
		return initialProgress + CGFloat(Date().timeIntervalSince1970 - initialTime) / Constants.duration
	}
	
	private func formatTime(from seconds: CGFloat) -> String {
		return dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(seconds)))
	}
}

// MARK: CAAnimationDelegate -

extension TimerViewController: CAAnimationDelegate {
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		if flag {
			state = .finished
		}
	}
}

// MARK: STATE -

private extension TimerViewController {
	enum State {
		case initial
		case running(startTime: TimeInterval, initialProgress: CGFloat)
		case paused(progress: CGFloat)
		case finished
	}
}

// MARK: CONSTANTS -

private extension TimerViewController {
	enum Constants {
		static let duration: CGFloat = 60
		
		static let startButtonTitle = "START"
		static let startButtonBackground = UIColor.systemGreen
	}
}
