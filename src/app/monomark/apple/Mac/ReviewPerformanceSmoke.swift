// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: dd141787-b620-42c4-a695-d8f9c5a28276
// COMPONENT: Native performance workload
// PURPOSE: Measure actual document readiness, rich rendering, search and navigation while an external sampler measures resources.
import AppKit
import WebKit

@MainActor enum ReviewPerformanceSmoke
{
    static func initialFile() throws -> URL
    {
        try inputFolder().appendingPathComponent("Intro.md")
    }

    static func run(session: ReaderSession) async throws -> [String: Any]
    {
        progress("benchmark-start", profile: "startup")
        var profiles: [[String: Any]] = []
        for (index, name) in ["1MiB", "10MiB"].enumerated()
        {
            var report = try await openProfile(session, name: name)
            report.merge(try await navigate(session, token: "END_PROFILE_\(index + 1)"))
            { _, new in
                new
            }
            try await idle(profile: name)
            report["passed"] = [
                "capturedFrameHasContent",
                "sourceBytesVerified",
                "boundedViewport",
                "searchFound",
                "jumpReturned"
            ]
            .allSatisfy
            {
                report[$0] as? Bool == true
            }
            profiles.append(report)
        }
        try await clear(session)
        return [
            "passed": profiles.allSatisfy
            {
                $0["passed"] as? Bool == true
            },
            "profiles": profiles,
            "timingDefinition": "Warm-app open. First visible is mounted content. First captured frame waits for a WebKit snapshot.",
            "resourceMeasurement": "External sampler reports the main app and an all-WebKit upper bound separately."
        ]
    }

    private static func clear(_ session: ReaderSession) async throws
    {
        let empty = try inputFolder().appendingPathComponent("Empty")
        session.openWorkspace(empty)
        guard await until({
            session.url == nil
        }) else
        {
            throw ReaderFailure.unavailable
        }
        try await idle(profile: "cleared")
    }

    private static func inputFolder() throws -> URL
    {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "--performance-input"), args.indices.contains(index + 1)
        else
        {
            throw ReaderFailure.unavailable
        }
        return URL(fileURLWithPath: args[index + 1], isDirectory: true)
    }

    private static func openProfile(_ session: ReaderSession, name: String) async throws -> [String: Any]
    {
        let source = try inputFolder().appendingPathComponent(name + ".md")
        var state = try ReadingState(
            id: DocumentAccess.identity(source),
            path: source.path,
            accessedAt: Date().timeIntervalSince1970
        )
        state.preferences = ReaderPreferences()
        let previous = session.smokeRendered
        let start = ProcessInfo.processInfo.systemUptime
        var visible: Double?
        session.smokeRendered = {
            if visible == nil
            {
                visible = elapsed(start)
            }
        }
        defer { session.smokeRendered = previous }
        progress("open-start", profile: name)
        session.open(source, folder: source.deletingLastPathComponent(), resume: state)
        guard await until({
            visible != nil
        }), let view = session.webView else
        {
            throw ReaderFailure.unavailable
        }
        return try await captureProfile(view, source: source, name: name, visible: visible, start: start)
    }

    private static func captureProfile(
        _ view: WKWebView,
        source: URL,
        name: String,
        visible: Double?,
        start: Double
    ) async throws -> [String: Any]
    {
        _ = try await view.evaluateJavaScript("window.MonoMark.command({type:'appearance',mode:'light'})")
        let image = try await view.takeSnapshot(configuration: nil)
        let captured = elapsed(start)
        try await waitDOM(
            view,
            """
            !!document.querySelector('.katex') && !!document.querySelector('.hljs') && \
            !!document.querySelector('[data-mermaid] svg') && document.querySelector('img')?.complete && \
            document.querySelector('img').naturalWidth>0
            """
        )
        return try await profileReport(
            view,
            source: source,
            name: name,
            visible: visible,
            captured: captured,
            rich: elapsed(start),
            image: image
        )
    }

    private static func profileReport(
        _ view: WKWebView,
        source: URL,
        name: String,
        visible: Double?,
        captured: Double,
        rich: Double,
        image: NSImage
    ) async throws -> [String: Any]
    {
        guard var report = try await view.evaluateJavaScript("window.MonoMark.metrics()") as? [String: Any]
        else
        {
            throw ReaderFailure.unavailable
        }
        report["profile"] = name
        report["firstVisibleMilliseconds"] = visible
        report["firstCapturedFrameMilliseconds"] = captured
        report["richReadyMilliseconds"] = rich
        report["capturedFrameHasContent"] = hasContent(image)
        report["sourceBytesVerified"] = report["sourceBytes"] as? Int ==
            (try source.resourceValues(forKeys: [.fileSizeKey])).fileSize
        report["boundedViewport"] = (report["mounted"] as? Int ?? 1000) <= 80
        return report
    }

    private static func navigate(_ session: ReaderSession, token: String) async throws -> [String: Any]
    {
        guard let view = session.webView
        else
        {
            throw ReaderFailure.unavailable
        }
        var start = ProcessInfo.processInfo.systemUptime
        session.command(["type": "find", "query": token])
        try await waitDOM(view, "document.getElementById('monomark-document').textContent.includes('\(token)')")
        let search = elapsed(start)
        start = ProcessInfo.processInfo.systemUptime
        session.command(["type": "jump", "id": "benchmark-start"])
        try await waitDOM(view, "!!document.getElementById('benchmark-start')")
        return [
            "searchMilliseconds": search,
            "jumpMilliseconds": elapsed(start),
            "searchFound": true,
            "jumpReturned": true
        ]
    }

    private static func hasContent(_ image: NSImage) -> Bool
    {
        guard let data = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: data)
        else
        {
            return false
        }
        for x in stride(from: 0, to: bitmap.pixelsWide, by: max(1, bitmap.pixelsWide / 100))
        {
            for y in stride(from: 0, to: bitmap.pixelsHigh, by: max(1, bitmap.pixelsHigh / 100))
            {
                if let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
                   min(color.redComponent, color.greenComponent, color.blueComponent) < 0.75
                {
                    return true
                }
            }
        }
        return false
    }

    private static func elapsed(_ start: Double) -> Double
    {
        (ProcessInfo.processInfo.systemUptime - start) * 1000
    }

    private static func idle(profile: String) async throws
    {
        try await Task.sleep(for: .milliseconds(500))
        progress("idle-start", profile: profile)
        try await Task.sleep(for: .seconds(5))
        progress("idle-end", profile: profile)
        try await Task.sleep(for: .milliseconds(300))
    }

    private static func progress(_ phase: String, profile: String)
    {
        let payload: [String: Any] = [
            "phase": phase,
            "profile": profile,
            "pid": ProcessInfo.processInfo.processIdentifier
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload)
        {
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
        }
    }

    private static func waitDOM(_ view: WKWebView, _ expression: String) async throws
    {
        for _ in 0 ..< 2000
        {
            if try await view.evaluateJavaScript(expression) as? Bool == true
            {
                return
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw NSError(
            domain: "MonoMarkPerformance",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "The native performance operation timed out."]
        )
    }

    private static func until(_ condition: () -> Bool) async -> Bool
    {
        for _ in 0 ..< 2000
        {
            if condition()
            {
                return true
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return false
    }
}
