// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 4abf5daf-7507-4ba7-b0b4-9b9fe62cba92
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Validate renderer messages and prevent document navigation from becoming browser navigation.
// RELATES: ReaderSession.swift
// FLOW: Native view -> validated session -> document surface.

import Foundation
import WebKit

/// Only the bundled top-level document may send bridge events or navigate the rendering surface.
@MainActor
final class WebCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate
{
    weak var session: ReaderSession?
    private var recovery = RendererRecovery()
    init(session: ReaderSession)
    {
        self.session = session
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
    {
        guard message.frameInfo.isMainFrame,
              message.frameInfo.request.url?.host == "bundle",
              let body = message.body as? [String: Any], body.count <= 12,
              let type = body["type"] as? String, type.count < 40
        else
        {
            return
        }
        session?.receive(body)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    )
    {
        let url = navigationAction.request.url
        if url?.scheme == "monomark", url?.host == "bundle"
        {
            decisionHandler(.allow)
        }
        else
        {
            if navigationAction.navigationType == .linkActivated, let url
            {
                session?.navigate(url.absoluteString)
            }
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)
    {
        session?.rendererReady = false
        session?.message = "The reader could not load. Select Refresh to retry."
        session?.isLoading = false
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView)
    {
        session?.rendererReady = false
        guard recovery.permitsReload(at: Date().timeIntervalSince1970)
        else
        {
            session?.message = "The reader stopped repeatedly. Select Refresh to retry."
            session?.isLoading = false
            return
        }
        session?.message = "The renderer stopped. Reload the document to continue."
        webView.reload()
    }

    func retryReader(_ webView: WKWebView)
    {
        recovery.reset()
        session?.rendererReady = false
        session?.isLoading = true
        webView.load(URLRequest(url: URL(string: "monomark://bundle/index.html")!))
    }
}
