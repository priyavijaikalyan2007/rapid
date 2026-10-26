// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 9ec1c213-f9f6-4cf5-a9c4-599aa7baa6a6
// Created: 2026
// COMPONENT: Native conversation preparation
// PURPOSE: Cover the app window and clear preparation synchronously when its scene becomes inactive.
// RELATES: PreparationCoordinator, PreparationService
// FLOW: Native controls -> bounded transient preparation -> explicit clear or lifecycle cleanup.

import UIKit

/// UIKit scene notifications arrive on the main thread. Only this view's scene is covered.
final class PreparationPrivacyShieldView: UIView
{
    private let onDeactivate: @MainActor () -> Void
    private var cover: UIView?

    init(onDeactivate: @escaping @MainActor () -> Void)
    {
        self.onDeactivate = onDeactivate
        super.init(frame: .zero)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deactivate),
            name: UIScene.willDeactivateNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activate),
            name: UIScene.didActivateNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder)
    {
        return nil
    }

    @objc private func deactivate(_ notification: Notification)
    {
        guard let scene = notification.object as? UIWindowScene, let window,
              scene === window.windowScene
        else
        {
            return
        }
        if cover == nil
        {
            cover = makeCover(in: window)
        }
        window.endEditing(true)
        onDeactivate()
    }

    @objc private func activate(_ notification: Notification)
    {
        guard let scene = notification.object as? UIWindowScene, scene === window?.windowScene
        else
        {
            return
        }
        cover?.removeFromSuperview()
        cover = nil
    }

    private func makeCover(in window: UIWindow) -> UIView
    {
        let shield = UIView(frame: window.bounds)
        shield.backgroundColor = .systemBackground
        shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        shield.accessibilityIdentifier = "prepare.privacyShield"
        let title = UILabel()
        title.text = "Composure"
        title.font = .preferredFont(forTextStyle: .title1)
        title.textColor = .label
        title.translatesAutoresizingMaskIntoConstraints = false
        shield.addSubview(title)
        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: shield.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: shield.centerYAnchor)
        ])
        window.addSubview(shield)
        return shield
    }

    override func didMoveToWindow()
    {
        super.didMoveToWindow()
        if window == nil
        {
            cover?.removeFromSuperview()
            cover = nil
        }
    }
}
