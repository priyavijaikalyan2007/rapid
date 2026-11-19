// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: e8e69f2e-ae6b-4e1b-afba-05f475a8cab1
// COMPONENT: Native appearance and window acceptance
// PURPOSE: Check actual appearance propagation, focusable document controls, and reversible single-display presentation.
import AppKit
import WebKit

@MainActor enum ReviewPresentationSmoke
{
    static func initialFile() throws -> URL
    {
        let file = try SmokeFixture.create()
        let extra = """

            ```csharp
            public class Reader { public bool Enabled = true; }
            ```

            | Section | Result |
            | --- | --- |
            | Appearance | Readable |

            > A synthetic callout.

            """
        let original = try Data(contentsOf: file)
        try (original + Data(extra.utf8)).write(to: file)
        return file
    }

    static func run(application: AppDelegate, output: String) async throws -> [String: Any]
    {
        guard let controller = application.current, let view = controller.session.webView
        else
        {
            throw ReaderFailure.unavailable
        }
        let originalMode = UserDefaults.standard.string(forKey: "appearance-mode")
        let launchMaximized = maximizedWindowMode(controller.window)
        let originalAppearance = NSApp.appearance
        defer
        {
            UserDefaults.standard.set(originalMode, forKey: "appearance-mode")
            NSApp.appearance = originalAppearance
        }
        controller.window?.setFrame(NSRect(x: 100, y: 100, width: 1280, height: 800), display: true)
        var report = try await fixedModes(controller, view: view, output: output)
        report["launchMaximizedInWindowMode"] = launchMaximized
        report.merge(try await systemModes(controller, view: view))
        { _, new in
            new
        }
        report.merge(try await readerChecks(application, controller: controller, view: view))
        { _, new in
            new
        }
        report["passed"] = checks.allSatisfy
        {
            report[$0] as? Bool == true
        }
        return report
    }

    private static let checks = [
        "launchMaximizedInWindowMode",
        "light",
        "dark",
        "system-dark",
        "system-light",
        "reloadRetainsMode",
        "light-fileRowContrast",
        "dark-fileRowContrast",
        "documentSemantics",
        "enlargedTypography",
        "singleDisplayPresentation"
    ]

    private static func maximizedWindowMode(_ window: NSWindow?) -> Bool
    {
        guard let window, let screen = window.screen
        else
        {
            return false
        }
        let frame = window.frame
        let available = screen.visibleFrame
        return abs(frame.minX - available.minX) < 1 && abs(frame.minY - available.minY) < 1 &&
            abs(frame.width - available.width) < 1 && abs(frame.height - available.height) < 1 &&
            window.styleMask.contains(.titled) && !window.styleMask.contains(.fullScreen)
    }

    private static func fixedModes(
        _ controller: ReaderWindowController,
        view: WKWebView,
        output: String
    ) async throws -> [String: Any]
    {
        var report: [String: Any] = [:]
        for mode in ["light", "dark"]
        {
            UserDefaults.standard.set(mode, forKey: "appearance-mode")
            report[mode] = try await appearance(view, window: controller.window, expected: mode)
            try await Task.sleep(for: .milliseconds(300))
            report[mode + "-fileRowContrast"] = try await captureWindow(
                controller.window,
                output: output + "." + mode + ".png",
                dark: mode == "dark"
            )
        }
        return report
    }

    private static func systemModes(
        _ controller: ReaderWindowController,
        view: WKWebView
    ) async throws -> [String: Any]
    {
        var report: [String: Any] = [:]
        UserDefaults.standard.set("system", forKey: "appearance-mode")
        for (name, native) in [("dark", NSAppearance.Name.darkAqua), ("light", .aqua)]
        {
            NSApp.appearance = NSAppearance(named: native)
            report["system-" + name] = try await appearance(view, window: controller.window, expected: name)
        }
        return report
    }

    private static func readerChecks(
        _ application: AppDelegate,
        controller: ReaderWindowController,
        view: WKWebView
    ) async throws -> [String: Any]
    {
        controller.session.refresh()
        try await Task.sleep(for: .milliseconds(400))
        return [
            "reloadRetainsMode": try await appearance(view, window: controller.window, expected: "light"),
            "nativeAccessibilityAcceptance": "External AX/VoiceOver acceptance remains pending.",
            "documentSemantics": try await semantics(view),
            "enlargedTypography": try await typography(controller.session, view: view),
            "singleDisplayPresentation": windows(application, controller: controller),
            "displayCount": NSScreen.screens.count,
            "reduceMotionEnabled": NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
            "increaseContrastEnabled": NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        ]
    }

    private static func appearance(_ view: WKWebView, window: NSWindow?, expected: String) async throws -> Bool
    {
        let dark = expected == "dark"
        for _ in 0 ..< 100
        {
            let mode = try await view.evaluateJavaScript("document.documentElement.style.colorScheme") as? String
            let nativeDark = window?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if mode == expected && nativeDark == dark
            {
                break
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        let expression = appearanceScript(expected: expected)
        for _ in 0 ..< 100
        {
            if try await view.evaluateJavaScript(expression) as? Bool == true
            {
                return window?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) ==
                    (dark ? .darkAqua : .aqua)
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        return false
    }

    private static func appearanceScript(expected: String) -> String
    {
        let dark = expected == "dark"
        return """
            (()=>{ const dark=\(dark), body=getComputedStyle(document.body);
            const rgb=s=>(s.match(/[\\d.]+/g)||[]).slice(0,3).map(Number);
            const [r,g,b]=rgb(body.backgroundColor), ink=rgb(body.color);
            const buttons=[...document.querySelectorAll('.monomark-artifact-actions button')];
            return document.documentElement.style.colorScheme==='\(expected)' &&
              (dark ? r+g+b<300 : r+g+b>600) && buttons.length>0 &&
              buttons.every(b=>b.getAttribute('aria-label')===b.title && b.tabIndex===0) &&
              document.querySelectorAll('.katex').length>0 && !!document.querySelector('[data-mermaid] svg') &&
              !!document.querySelector('code.hljs .hljs-keyword') && !!document.querySelector('table th'); })()
            """
    }

    private static func semantics(_ view: WKWebView) async throws -> Bool
    {
        try await view.evaluateJavaScript("""
            (()=>{const main=document.querySelector('main'), button=document.querySelector('.monomark-artifact-image button');
            if(!button) return false; button.focus();
            return main?.getAttribute('aria-label')==='Rendered Markdown' && main.tabIndex===0 &&
              document.activeElement===button && document.querySelector('h1') &&
              [...document.querySelectorAll('img')].every(i=>!!i.alt) &&
              [...document.querySelectorAll('[role=group]')].every(g=>!!g.getAttribute('aria-label')); })()
            """) as? Bool == true
    }

    private static func typography(_ session: ReaderSession, view: WKWebView) async throws -> Bool
    {
        session.preferences.bodySize = 28
        session.preferences.headingSizes[0] = 44
        session.updatePreferences()
        for _ in 0 ..< 100
        {
            if try await view.evaluateJavaScript("""
                getComputedStyle(document.body).fontSize==='28px' &&
                getComputedStyle(document.querySelector('h1')).fontSize==='44px' &&
                window.MonoMark.metrics().mounted<=80
                """) as? Bool == true
            {
                return true
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        return false
    }

    private static func captureWindow(_ window: NSWindow?, output: String, dark: Bool) async throws -> Bool
    {
        guard let window
        else
        {
            return false
        }
        let bitmap = try await ReviewWindowCapture.write(window, output: output)
        return !bitmap.hasAlpha && bitmap.pixelsWide == 2560 && bitmap.pixelsHigh == 1600 &&
            filenameHasInk(bitmap, dark: dark)
    }

    private static func filenameHasInk(_ bitmap: NSBitmapImageRep, dark: Bool) -> Bool
    {
        // Fixed synthetic window: inspect only filename glyphs, excluding its icon and selection checkmark.
        let scale = Double(bitmap.pixelsWide) / 1280
        var ink = 0
        for x in Int(48 * scale) ..< Int(142 * scale)
        {
            for y in Int(151 * scale) ..< Int(164 * scale)
            {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB)
                else
                {
                    continue
                }
                let channels = [color.redComponent, color.greenComponent, color.blueComponent]
                if dark ? channels.min()! > 0.65 : channels.max()! < 0.3
                {
                    ink += 1
                }
            }
        }
        return ink > 20
    }

    private static func windows(_ application: AppDelegate, controller: ReaderWindowController) -> Bool
    {
        guard let window = controller.window, let screen = window.screen
        else
        {
            return false
        }
        let second = application.createWindow()
        defer { second.close() }
        let otherFrame = second.window?.frame
        let originalFrame = window.frame
        let originalStyle = window.styleMask
        controller.togglePresentation()
        let full = window.frame == screen.frame && window.styleMask.contains(.borderless)
        window.cancelOperation(nil)
        let restored = window.styleMask == originalStyle && window.frame == originalFrame
        window.cancelOperation(nil)
        return full && restored && window.isVisible && second.window?.frame == otherFrame
    }
}
