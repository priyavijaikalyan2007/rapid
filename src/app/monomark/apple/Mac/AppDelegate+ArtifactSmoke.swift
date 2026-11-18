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
                do
                {
                    if ProcessInfo.processInfo.arguments.contains("--performance-smoke")
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
                    report = [
                        "passed": false,
                        "error": error.localizedDescription,
                        "detail": (error as NSError).userInfo.description
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
