// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: d0ff5eca-edb3-4425-b6f8-a3109457aa6c
// COMPONENT: Mobile document session coordinator
// PURPOSE: Configure every document tab and retain stable selection while pending notes finish saving.
// FLOW: Native tab action -> stable identity -> reader session -> existing persistence services.
import SwiftUI

@MainActor
final class MobileReaderTabs: ObservableObject
{
    @Published private(set) var selection: DocumentTabSelection
    @Published private(set) var current: ReaderSession
    private var sessions: [UUID: ReaderSession]

    init()
    {
        let id = UUID()
        let session = Self.makeSession()
        current = session
        sessions = [id: session]
        selection = DocumentTabSelection(first: id)
        configure(session)
    }

    func session(_ id: UUID) -> ReaderSession?
    {
        sessions[id]
    }

    func select(_ id: UUID)
    {
        guard id != selection.selectedID, let session = sessions[id]
        else
        {
            return
        }
        checkpointCurrent()
        selection.select(id)
        session.rendererReady = false
        current = session
    }

    func newTab(file: URL? = nil, folder: URL? = nil, fragment: String? = nil)
    {
        checkpointCurrent()
        let id = UUID()
        let session = Self.makeSession()
        configure(session)
        session.showSidebar = false
        sessions[id] = session
        selection.append(id)
        current = session
        if let file
        {
            session.open(file, folder: folder, fragment: fragment)
        }
    }

    func closeCurrent() async
    {
        let id = selection.selectedID
        let closing = current
        guard await closing.annotations.drain()
        else
        {
            closing.message = closing.annotations.error ?? "The reading notes could not be saved."
            return
        }
        var remaining = selection
        guard remaining.remove(id), let next = sessions[remaining.selectedID]
        else
        {
            return
        }
        closing.close()
        sessions.removeValue(forKey: id)
        selection = remaining
        next.rendererReady = false
        current = next
    }

    func checkpointAll() async
    {
        let opened = Array(sessions.values)
        for session in opened
        {
            session.checkpoint()
            _ = await session.annotations.drain()
        }
    }

    private func checkpointCurrent()
    {
        current.checkpoint()
        current.rendererReady = false
        current.showSidebar = false
        current.annotations.shown = false
    }

    private static func makeSession() -> ReaderSession
    {
        #if DEBUG
        ReaderSession(defaults: MobileReviewFixture.defaults, storageDirectory: MobileReviewFixture.storageDirectory)
        #else
        ReaderSession()
        #endif
    }

    private func configure(_ session: ReaderSession)
    {
        session.openNewTab = { [weak self] file, folder, fragment in
            self?.newTab(file: file, folder: folder, fragment: fragment)
        }
        session.titleChanged = { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}
