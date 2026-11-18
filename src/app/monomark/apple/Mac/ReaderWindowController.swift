// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 1050e185-6e16-4af5-8cc3-65cf250068f4
// Created: 2026
// COMPONENT: MonoMark platform app
// PURPOSE: Manage native document tabs, scoped full screen, and rendered printing.
// RELATES: ReaderSession.swift, ReaderView.swift
// FLOW: Platform event -> native document window -> reader session.

import AppKit
import SwiftUI
import WebKit

/// Each native document tab owns a session and releases its scope when closed.
@MainActor
final class ReaderWindowController: NSWindowController, NSWindowDelegate
{
    let session = ReaderSession()
    var pendingRecord: ReadingState?
    weak var application: AppDelegate?
    private var savedFrame: NSRect?
    private var savedStyle: NSWindow.StyleMask?
    private var savedLevel: NSWindow.Level?
    private var allowClose = false
    private var printJob: ReaderPrintJob?

    init(application: AppDelegate)
    {
        self.application = application
        let window = ReaderWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1120, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = "MonoMark"
        window.minSize = NSSize(width: 650, height: 400)
        window.tabbingMode = .preferred
        window.tabbingIdentifier = "MonoMark-Documents"
        window.delegate = self
        window.contentViewController = NSHostingController(rootView: ReaderView(
            session: session,
            openFile: { [weak application] in
                application?.openFile(nil)
            },
            openFolder: { [weak application] in
                application?.openFolder(nil)
            }
        ))
        window.setContentSize(NSSize(width: 1120, height: 780))
        window.togglePresentation = { [weak self] in
            self?.togglePresentation()
        }
        window.dismissTemporary = { [weak session] in
            guard let session, session.showFind
            else
            {
                return false
            }
            session.showFind = false
            return true
        }
        session.titleChanged = { [weak window, weak session, weak application] _ in
            if let file = session?.url
            {
                window?.title = DocumentPresentation.title(file)
                window?.representedURL = file
            }
            else
            {
                window?.title = session?.root?.path ?? "MonoMark"
                window?.representedURL = session?.root
            }
            application?.saveTabs()
        }
        session.openNewTab = { [weak self, weak application] file, folder in
            application?.createWindow(file: file, folder: folder, tabbedWith: self)
        }
        session.printAction = { [weak self] in
            self?.printDocument()
        }
        session.exportAction = { [weak session, weak application] options, destination in
            guard let session
            else
            {
                return
            }
            application?.performReadingExport(session, options: options, destination: destination)
        }
    }

    required init?(coder: NSCoder)
    {
        nil
    }

    @objc func copyDocumentPath(_ sender: Any?)
    {
        if let file = session.url
        {
            session.copy(file.path)
        }
    }

    func togglePresentation()
    {
        guard let window
        else
        {
            return
        }
        if let frame = savedFrame, let style = savedStyle
        {
            window.styleMask = style
            window.level = savedLevel ?? .normal
            window.hidesOnDeactivate = false
            let visible = window.screen?.visibleFrame ?? frame
            var restored = frame
            restored.size.width = min(frame.width, visible.width)
            restored.size.height = min(frame.height, visible.height)
            restored.origin.x = max(visible.minX, min(frame.minX, visible.maxX - restored.width))
            restored.origin.y = max(visible.minY, min(frame.minY, visible.maxY - restored.height))
            window.setFrame(restored, display: true)
            savedFrame = nil
            savedStyle = nil
            return
        }
        let screen = NSScreen.screens.max
        { lhs, rhs in
            lhs.frame.intersection(window.frame).area < rhs.frame.intersection(window.frame).area
        } ?? window.screen ?? NSScreen.main
        guard let screen
        else
        {
            return
        }
        savedFrame = window.frame
        savedStyle = window.styleMask
        savedLevel = window.level
        window.styleMask = [.borderless, .resizable]
        window.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 1)
        window.hidesOnDeactivate = true
        window.setFrame(screen.frame, display: true)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool
    {
        if allowClose ||
            (session.annotations.pending == 0 && !session.annotations.notesDirty && !session.annotations.hasFailedEdits)
        {
            return true
        }
        Task
        {
            if await session.annotations.drain()
            {
                allowClose = true
                sender.performClose(nil)
            }
        }
        return false
    }

    func windowWillClose(_ notification: Notification)
    {
        session.close()
        application?.controllers.removeAll
        {
            $0 === self
        }
    }

    func windowDidBecomeKey(_ notification: Notification)
    {
        session.isSuspended = false
        if let pendingRecord
        {
            self.pendingRecord = nil
            session.reopen(pendingRecord)
        }
    }

    func windowDidResignKey(_ notification: Notification)
    {
        Task
        { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard let self, let window, !window.isKeyWindow,
                  let group = window.tabGroup, group.selectedWindow !== window
            else
            {
                return
            }
            session.checkpoint()
            session.isSuspended = true
            session.rendererReady = false
        }
    }

    func printDocument()
    {
        guard let view = session.webView, let window
        else
        {
            return
        }
        guard let info = printInformation()
        else
        {
            return
        }
        let operation = view.printOperation(with: info)
        let ticket = session.documentEpoch
        printJob = ReaderPrintJob(operation: operation)
        { [weak self] _ in
            guard let self
            else
            {
                return
            }
            if session.documentEpoch == ticket
            {
                session.command(["type": "afterPrint"])
            }
            printJob = nil
        }
        printJob?.start(window: window)
    }

    private func printInformation() -> NSPrintInfo?
    {
        guard let info = NSPrintInfo.shared.copy() as? NSPrintInfo
        else
        {
            return nil
        }
        let paper = session.paperLayout
        if session.preferences.paperSize != "system"
        {
            info.orientation = .portrait
            info.paperSize = NSSize(width: paper.widthPoints, height: paper.heightPoints)
        }
        info.topMargin = paper.marginPoints
        info.bottomMargin = paper.marginPoints
        info.leftMargin = paper.marginPoints
        info.rightMargin = paper.marginPoints
        return info
    }
}

private extension NSRect
{
    var area: CGFloat
    {
        isNull ? 0 : width * height
    }
}
