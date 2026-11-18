// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 9b1ae02b-5b8b-4bbd-8bdf-0b6ab16800ba
// COMPONENT: Real WebKit smoke harness
// PURPOSE: Verify native rendering, annotations, export, and bounded PNG capture.
// FLOW: Isolated demo -> reader actions -> evidence files -> terminate.

import AppKit
import WebKit

extension AppDelegate
{
    func configureSmoke(output requested: String)
    {
        let output = SmokeOutput.resolve(requested)
        current?.session.smokeRendered = { [weak self] in
            guard let self, !smokeStarted, let view = current?.session.webView
            else
            {
                return
            }
            smokeStarted = true
            Task
            { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                _ = try? await view.evaluateJavaScript("""
                    (() => { const text = document.querySelector('.monomark-block p');
                    const range = document.createRange(); range.selectNodeContents(text);
                    window.getSelection().removeAllRanges(); window.getSelection().addRange(range);
                    document.dispatchEvent(new MouseEvent('mouseup', {bubbles:true})); })()
                    """)
                try? await Task.sleep(for: .milliseconds(100))
                if let notes = self.current?.session.annotations
                {
                    notes.addSelection()
                    if var annotation = notes.records.first
                    {
                        annotation.comment = "A native smoke comment."
                        notes.update(annotation)
                    }
                    notes.editNotes("# Smoke notes\nKeep reading data local.")
                    _ = await notes.drain()
                    notes.reload()
                    try? await Task.sleep(for: .milliseconds(200))
                }
                if let session = self.current?.session, let source = session.url
                {
                    let notes = ReadingNotes(
                        annotations: session.annotations.records,
                        text: session.annotations.text,
                        format: session.annotations.format
                    )
                    try? AnnotationExportWriter.write(
                        source: source,
                        destination: URL(fileURLWithPath: output + ".export.md"),
                        notes: notes
                    )
                }
                self.current?.session.command(["type": "jump", "id": "monomark-diagram-1"])
                try? await Task.sleep(for: .seconds(5))
                _ = try? await view.evaluateJavaScript("window.MonoMark.command({type:'appearance',mode:'dark'})")
                try? await Task.sleep(for: .seconds(1))
                _ = try? await view
                    .evaluateJavaScript(
                        "document.querySelector('.monomark-artifact-diagram button[title*=PNG]')?.click()"
                    )
                try? await Task.sleep(for: .seconds(2))
                if let anchor = self.current?.session.annotations.records.first?.anchors.first
                {
                    self.current?.session.command(["type": "jump", "id": anchor.blockID])
                    try? await Task.sleep(for: .seconds(1))
                }
                let result = try? await view
                    .evaluateJavaScript(
                        """
                        ({ ...window.MonoMark.metrics(), text: document.body.innerText.slice(0,1000), math: \
                        document.querySelectorAll('.katex').length, diagrams: \
                        document.querySelectorAll('.monomark-diagram svg').length, copyButtons: document.querySelectorAll('.monomark-artifact-actions button').length, appearance: document.documentElement.style.colorScheme })
                        """
                    )
                var report = result as? [String: Any] ?? [:]
                report["nativeCopyRequest"] = self.current?.session.lastCopyRequest
                report["nativeStatus"] = self.current?.session.message
                report["nativeAnnotationCount"] = self.current?.session.annotations.records.count
                report["nativeNotesRecovered"] = self.current?.session.annotations.text == "# Smoke notes\nKeep reading data local."
                report["annotationSaveError"] = self.current?.session.annotations.error ?? ""
                report["editingMenu"] = NSApp.mainMenu?.item(withTitle: "Edit")?.submenu?.items.map(\.title)
                report["highlightCount"] = try? await view
                    .evaluateJavaScript("document.querySelectorAll('mark[data-annotation]').length")
                if let data = try? JSONSerialization.data(
                    withJSONObject: report,
                    options: [.prettyPrinted, .sortedKeys]
                )
                {
                    try? data.write(to: URL(fileURLWithPath: output))
                    if requested == "-"
                    {
                        FileHandle.standardOutput.write(data)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2)
                {
                    NSApp.terminate(nil)
                }
                view.takeSnapshot(with: nil)
                { image, _ in
                    if let image, let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
                       let png = bitmap.representation(using: .png, properties: [:])
                    {
                        try? png.write(to: URL(fileURLWithPath: output + ".png"))
                    }
                    NSApp.terminate(nil)
                }
            }
        }
    }
}
