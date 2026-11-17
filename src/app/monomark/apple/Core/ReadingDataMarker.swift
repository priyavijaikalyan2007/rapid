// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// File GUID: 70b6a3d1-23f7-42b6-8138-dca4e0580012
// COMPONENT: Generated-section markers
// PURPOSE: Recognize only app-owned standalone boundaries.
import Foundation

struct ReadingDataMarker
{
    let id: String
    let starts: Bool
    let joinsPreviousLine: Bool

    static func parse(_ line: String) throws -> Self?
    {
        if line == AnnotationExporter.start
        {
            return Self(id: "footer", starts: true, joinsPreviousLine: false)
        }
        if line == AnnotationExporter.end
        {
            return Self(id: "footer", starts: false, joinsPreviousLine: false)
        }
        let prefix = "<!-- monomark:inline:"
        guard line.hasPrefix(prefix)
        else
        {
            return nil
        }
        guard line.hasSuffix(" -->")
        else
        {
            throw AnnotationFailure.invalidMarkers
        }
        let fields = line.dropFirst(prefix.count).dropLast(4).split(separator: ":", omittingEmptySubsequences: false)
        guard fields.count == 2 || fields.count == 3,
              fields[0] == "notes" || UUID(uuidString: String(fields[0])) != nil,
              fields[1] == "start" || fields[1] == "end",
              fields.count == 2 || (fields[1] == "start" && fields[2] == "join")
        else
        {
            throw AnnotationFailure.invalidMarkers
        }
        return Self(id: String(fields[0]), starts: fields[1] == "start", joinsPreviousLine: fields.count == 3)
    }

    static func start(id: String, join: Bool) -> String
    {
        "<!-- monomark:inline:\(id):start\(join ? ":join" : "") -->"
    }

    static func end(id: String) -> String
    {
        "<!-- monomark:inline:\(id):end -->"
    }
}
