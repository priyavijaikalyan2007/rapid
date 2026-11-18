// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 36090801-9bb7-4c0a-aefd-a4af561635f2
// Created: 2026
// COMPONENT: MonoMark native UI
// PURPOSE: Serve packaged scripts and narrowly scoped document resources without a local server.
// RELATES: ReaderSession.swift
// FLOW: Native view -> validated session -> document surface.

import Foundation
import WebKit
import UniformTypeIdentifiers

/// A custom origin grants access only to packaged assets and the current user-authorized document scope.
@MainActor
final class ResourceHandler: NSObject, WKURLSchemeHandler
{
    weak var session: ReaderSession?
    private var tasks: [ObjectIdentifier: Task<Void, Never>] = [:]

    init(session: ReaderSession)
    {
        self.session = session
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask)
    {
        let key = ObjectIdentifier(urlSchemeTask)
        let request = urlSchemeTask.request.url
        let source = session?.url
        let epoch = session?.documentEpoch
        let root = session?.root
        if request?.host == "document", request?.path == "/source"
        {
            let epoch = request.flatMap
            {
                URLComponents(url: $0, resolvingAgainstBaseURL: false)
            }?
            .queryItems?.first(where: {
                $0.name == "epoch"
            })?.value
            guard epoch == session?.documentEpoch
            else
            {
                urlSchemeTask.didFailWithError(ReaderFailure.denied)
                return
            }
        }
        tasks[key] = Task
        {
            do
            {
                guard let request
                else
                {
                    throw ReaderFailure.unavailable
                }
                let resource = try await Task.detached(priority: .userInitiated)
                {
                    try Self.read(request, source: source, root: root)
                }.value
                guard !Task.isCancelled, tasks[key] != nil
                else
                {
                    return
                }
                if let identity = resource.3, let source, let epoch
                {
                    session?.reconcileSourceIdentity(identity, file: source, epoch: epoch)
                }
                let response = HTTPURLResponse(
                    url: request,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: [
                        "Content-Type": resource.1,
                        "X-MonoMark-Source-Hash": resource.2 ?? "",
                        "Access-Control-Expose-Headers": "X-MonoMark-Source-Hash",
                        "Access-Control-Allow-Origin": "*",
                        "Cache-Control": "no-store"
                    ]
                )!
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(resource.0)
                urlSchemeTask.didFinish()
            }
            catch
            {
                if !Task.isCancelled, tasks[key] != nil
                {
                    urlSchemeTask.didFailWithError(error)
                }
            }
            tasks[key] = nil
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask)
    {
        let key = ObjectIdentifier(urlSchemeTask)
        tasks.removeValue(forKey: key)?.cancel()
    }

    nonisolated private static func read(
        _ request: URL,
        source: URL?,
        root: URL?
    ) throws -> (Data, String, String?, String?)
    {
        if request.host == "bundle"
        {
            guard let folder = Bundle.main.resourceURL?.appendingPathComponent("Renderer")
            else
            {
                throw ReaderFailure.unavailable
            }
            let file = folder.appendingPathComponent(request.path)
            guard DocumentAccess.contains(file, in: folder)
            else
            {
                throw ReaderFailure.denied
            }
            return (try Data(contentsOf: file), mime(file), nil, nil)
        }
        guard request.host == "document", let source, let root
        else
        {
            throw ReaderFailure.denied
        }
        if request.path == "/source"
        {
            let snapshot = try DocumentAccess.snapshot(source)
            return (
                snapshot.data,
                "text/plain; charset=utf-8",
                DocumentStamp.make(String(decoding: snapshot.data, as: UTF8.self)),
                snapshot.identity
            )
        }
        let raw = URLComponents(url: request, resolvingAgainstBaseURL: false)?.queryItems?
            .first(where: {
                $0.name == "path"
            })?.value
        guard request.path == "/image", let raw,
              case .file(let file) = LinkPolicy.resolve(raw, relativeTo: source, root: root),
              ["png", "jpg", "jpeg", "gif", "webp", "heic", "tiff", "bmp"].contains(file.pathExtension.lowercased())
        else
        {
            throw ReaderFailure.denied
        }
        let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? Int.max
        guard size <= 20 * 1024 * 1024
        else
        {
            throw ReaderFailure.oversized
        }
        return (try Data(contentsOf: file), mime(file), nil, nil)
    }

    nonisolated private static func mime(_ file: URL) -> String
    {
        switch file.pathExtension.lowercased()
        {
        case "js", "mjs": "text/javascript; charset=utf-8"
        case "css": "text/css; charset=utf-8"
        case "html": "text/html; charset=utf-8"
        default: UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        }
    }
}
