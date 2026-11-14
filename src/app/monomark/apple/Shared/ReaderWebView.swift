// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 5b3fb865-2de0-4971-922d-32812ba99346
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Bridge a reusable offline WKWebView into native reader layouts.
// RELATES: ReaderSession.swift
// FLOW: Native view -> validated session -> document surface.

import SwiftUI
import WebKit

#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
#else
typealias PlatformViewRepresentable = UIViewRepresentable
#endif

/// The document host uses no persistent browser storage and loads only bundled application code.
struct ReaderWebView: PlatformViewRepresentable
{
    @ObservedObject var session: ReaderSession
    func makeCoordinator() -> WebCoordinator
    {
        WebCoordinator(session: session)
    }

    private func create(context: Context) -> WKWebView
    {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.setURLSchemeHandler(ResourceHandler(session: session), forURLScheme: "monomark")
        configuration.userContentController.add(context.coordinator, name: "reader")
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.isInspectable = ProcessInfo.processInfo.arguments.contains("--demo")
        session.webView = view
        view.load(URLRequest(url: URL(string: "monomark://bundle/index.html")!))
        return view
    }

    #if os(macOS)
    func makeNSView(context: Context) -> WKWebView
    {
        create(context: context)
    }

    func updateNSView(_ nsView: WKWebView, context: Context)
    {
    }
    #else
    func makeUIView(context: Context) -> WKWebView
    {
        create(context: context)
    }

    func updateUIView(_ uiView: WKWebView, context: Context)
    {
    }
    #endif
}
