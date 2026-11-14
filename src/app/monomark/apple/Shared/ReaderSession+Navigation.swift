// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: af2d0f79-aad7-4c55-a9db-6d28d0d17d02
// Created: 2026
// COMPONENT: MonoMark session adapter
// PURPOSE: Isolate Navigation from document lifecycle and persistence.
// RELATES: ReaderSession.swift
// FLOW: Native action -> validated session operation.

import Foundation
import SwiftUI
import WebKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension ReaderSession
{
    func navigate(_ href: String, newTab: Bool = false)
    {
        guard let url, let root
        else
        {
            return
        }
        switch LinkPolicy.resolve(href, relativeTo: url, root: root)
        {
        case .fragment(let id): command(["type": "jump", "id": id])
        case .document(let target, let fragment):
            if newTab, let openNewTab { openNewTab(target, root) }
            else { open(target, folder: root, fragment: fragment) }
        case .external(let target):
            #if os(macOS)
            NSWorkspace.shared.open(target)
            #else
            UIApplication.shared.open(target)
            #endif
        case .file(let target):
            #if os(macOS)
            NSWorkspace.shared.open(target)
            #else
            UIApplication.shared.open(target)
            #endif
        case .denied: message = ReaderFailure.denied.localizedDescription
        }
    }

    func preview(_ href: String)
    {
        guard let url, let root
        else
        {
            return
        }
        let ticket = documentEpoch
        Task
        {
            var text = "Preview available for Markdown files inside the opened folder."
            if case .document(let target, _) = LinkPolicy.resolve(href, relativeTo: url, root: root)
            {
                text = (try? await Task.detached
                {
                    try PreviewLoader.load(target, root: root)
                }.value)
                    ?? "The preview is unavailable. Open the file or its folder to check access."
            }
            guard ticket == documentEpoch
            else
            {
                return
            }
            command(["type": "preview", "href": href, "text": text])
        }
    }
}
