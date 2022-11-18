//
//  SceneDelegate.swift
//  Timer
//
//  Created by Dima on 17.11.2022.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	
	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let windowScene = scene as? UIWindowScene else { return }
		let window = UIWindow(windowScene: windowScene)
		window.rootViewController = TimerViewController(nibName: nil, bundle: nil)
		self.window = window
		window.makeKeyAndVisible()
	}
}

