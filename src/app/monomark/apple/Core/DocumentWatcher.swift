// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 33445dde-cc3a-426d-a088-80d2d8207809
// COMPONENT: Coalesced document observation
// PURPOSE: Detect in-place changes and atomic replacement without polling.
import Darwin
import Foundation

/// The directory watch survives editor replacements. File identity filters unrelated directory activity.
@MainActor final class DocumentWatcher
{
    private let file: URL
    private let onChange: @MainActor () -> Void
    private var fingerprint: FileFingerprint?
    private var fileSource: DispatchSourceFileSystemObject?
    private var directorySource: DispatchSourceFileSystemObject?
    private var pending: Task<Void, Never>?
    private var stopped = false
    private var fileEvent = false

    init(file: URL, onChange: @escaping @MainActor () -> Void)
    {
        self.file = file
        self.onChange = onChange
        fingerprint = FileFingerprint.read(file)
        fileSource = observe(file, targetFile: true)
        directorySource = observe(file.deletingLastPathComponent(), targetFile: false)
    }

    isolated deinit
    {
        pending?.cancel()
        fileSource?.cancel()
        directorySource?.cancel()
    }

    func cancel()
    {
        stopped = true
        pending?.cancel()
        pending = nil
        fileSource?.cancel()
        directorySource?.cancel()
        fileSource = nil
        directorySource = nil
    }

    private func observe(_ url: URL, targetFile: Bool) -> DispatchSourceFileSystemObject?
    {
        let descriptor = Darwin.open(url.path, O_EVTONLY | O_CLOEXEC)
        guard descriptor >= 0
        else
        {
            return nil
        }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: [.write, .rename, .delete, .attrib], queue: .main
        )
        source.setEventHandler
        { [weak self] in
            Task
            { @MainActor in
                self?.schedule(targetFile: targetFile)
            }
        }
        source.setCancelHandler
        {
            Darwin.close(descriptor)
        }
        source.resume()
        return source
    }

    private func schedule(targetFile: Bool)
    {
        guard !stopped
        else
        {
            return
        }
        fileEvent = fileEvent || targetFile
        pending?.cancel()
        pending = Task
        { [weak self] in
            do
            {
                try await Task.sleep(for: .milliseconds(250))
            }
            catch
            {
                return
            }
            self?.check()
        }
    }

    private func check()
    {
        guard !stopped
        else
        {
            return
        }
        let current = FileFingerprint.read(file)
        let changed = current != fingerprint || fileEvent
        fileEvent = false
        guard changed
        else
        {
            return
        }
        let replaced = current?.inode != fingerprint?.inode
        fingerprint = current
        if replaced
        {
            fileSource?.cancel()
            fileSource = observe(file, targetFile: true)
        }
        onChange()
    }
}
