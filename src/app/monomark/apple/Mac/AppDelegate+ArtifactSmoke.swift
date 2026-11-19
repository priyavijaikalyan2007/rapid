// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: b76b2f71-d3dd-4653-9535-f9ad488e8620
// COMPONENT: Native artifact acceptance entry point
// PURPOSE: Record bounded machine-readable clipboard evidence without changing the user's pasteboard.
import AppKit
import Darwin

extension AppDelegate
{
    func configureArtifactSmoke(output requested: String, review: Bool = false)
    {
        let output = SmokeOutput.resolve(requested)
        current?.session.smokeRendered = { [weak self] in
            guard let self, !smokeStarted, let session = current?.session
            else
            {
                return
            }
            smokeStarted = true
            Task
            {
                let report: [String: Any]
                let initialEpoch = session.documentEpoch
                let initialView = session.webView
                do
                {
                    if ProcessInfo.processInfo.arguments.contains("--store-screenshots")
                    {
                        report = try await ReviewStoreScreenshots.run(application: self, output: output)
                    }
                    else if ProcessInfo.processInfo.arguments.contains("--presentation-smoke")
                    {
                        report = try await ReviewPresentationSmoke.run(application: self, output: output)
                    }
                    else if ProcessInfo.processInfo.arguments.contains("--performance-smoke")
                    {
                        report = try await ReviewPerformanceSmoke.run(session: session)
                    }
                    else if ProcessInfo.processInfo.arguments.contains("--lifecycle-smoke")
                    {
                        report = try await ReviewLifecycleSmoke.run(application: self)
                    }
                    else if review
                    {
                        report = try await ReviewSmoke.run(session: session, output: output)
                    }
                    else
                    {
                        report = try await ArtifactSmoke.run(session: session, output: output)
                    }
                }
                catch
                {
                    let diagnostic = try? await session.webView?.evaluateJavaScript("""
                        ({ scrollY: window.scrollY, viewportHeight: window.innerHeight,
                           headings: [...document.querySelectorAll('h1,h2')].map(x=>x.id),
                           math: !!document.querySelector('.katex'),
                           diagram: !!document.querySelector('[data-mermaid] svg'),
                           image: document.querySelector('img')?.naturalWidth || 0,
                           selection: window.getSelection().toString().slice(0, 500),
                           ranges: window.getSelection().rangeCount,
                           text: document.body.innerText.slice(0, 2000) })
                        """)
                    report = [
                        "passed": false,
                        "error": error.localizedDescription,
                        "detail": (error as NSError).userInfo.description,
                        "domDiagnostic": diagnostic ?? [:],
                        "sessionSuspended": session.isSuspended,
                        "viewAttached": session.webView?.window != nil,
                        "epochChanged": initialEpoch != session.documentEpoch,
                        "viewReplaced": initialView !== session.webView
                    ]
                }
                if let data = try? JSONSerialization.data(
                    withJSONObject: report,
                    options: [.prettyPrinted, .sortedKeys]
                )
                {
                    try? data.write(to: URL(fileURLWithPath: output))
                    if requested == "-"
                    {
                        FileHandle.standardOutput.write(data)
                        FileHandle.standardOutput.write(Data("\n".utf8))
                    }
                }
                // This isolated CLI harness has no user documents. Flush its fixture notes before returning a test exit
                // code.
                guard await session.annotations.drain()
                else
                {
                    exit(EXIT_FAILURE)
                }
                session.close()
                exit(report["passed"] as? Bool == true ? EXIT_SUCCESS : EXIT_FAILURE)
            }
        }
    }
}
