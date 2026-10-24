// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 38c5c58f-a51d-41be-ad93-6c4ca381eab5
// Created: 2026
// COMPONENT: CropPreset
// PURPOSE: Adds PassportGuides behavior to CropPreset.
// RELATES: [[CropPrint]]
// FLOW: Native application -> CropPreset -> local result.

import Foundation
import SwiftUI

/// Adds PassportGuides behavior to CropPreset.
extension CropPreset
{
    /// Passport guide used by CropPreset.
    var passportGuide: PassportGuide?
    {
        Self.passportGuides[self]
    }

    /// Creates one authored guide and omits an entry if its constant address is invalid.
    private static func guide(
        crown: ClosedRange<CGFloat>,
        chin: ClosedRange<CGFloat>,
        measurement: String,
        source: String,
        url: String
    ) -> PassportGuide?
    {
        guard let sourceURL = URL(string: url)
        else
        {
            return nil
        }
        return PassportGuide(
            crownBand: crown,
            chinBand: chin,
            measurement: measurement,
            sourceName: source,
            sourceURL: sourceURL
        )
    }

    /// Source-backed guide data. Invalid authored addresses cannot crash the application.
    private static let passportGuides: [Self: PassportGuide] = ([
        .passportIndia: guide(
            crown: 0.07 ... 0.16,
            chin: 0.63 ... 0.84,
            measurement: "Head height: 25–35 mm",
            source: "Passport Seva, India",
            url: "https://www.passportindia.gov.in/AppOnlineProject/pdf/Photograph_Guidelines.pdf"
        ),
        .passportUS: guide(
            crown: 0.08 ... 0.18,
            chin: 0.58 ... 0.76,
            measurement: "Head height: 1–1⅜ inches",
            source: "U.S. Department of State",
            url: "https://travel.state.gov/content/travel/en/passports/how-apply/photos.html"
        ),
        .passportCanada: guide(
            crown: 0.14 ... 0.22,
            chin: 0.58 ... 0.72,
            measurement: "Face height: 31–36 mm",
            source: "Government of Canada",
            url: "https://www.canada.ca/en/immigration-refugees-citizenship/services/canadian-passports/photos.html"
        ),
        .passportEurope: guide(
            crown: 0.05 ... 0.14,
            chin: 0.76 ... 0.92,
            measurement: "Common guide: head height about 32–36 mm",
            source: "European Commission",
            url: "https://home-affairs.ec.europa.eu/policies/schengen-borders-and-visa/document-security_en"
        ),
        .passportUK: guide(
            crown: 0.07 ... 0.16,
            chin: 0.71 ... 0.91,
            measurement: "Head height: 29–34 mm",
            source: "GOV.UK",
            url: "https://www.gov.uk/photos-for-passports"
        ),
        .passportChina: guide(
            crown: 0.06 ... 0.11,
            chin: 0.64 ... 0.80,
            measurement: "Head height: 28–33 mm",
            source: "Chinese consular guidance",
            url: "https://cs.mfa.gov.cn/zggmcg/ppp/hz/zhengjian/202007/t20200720_961088.shtml"
        ),
        .passportJapan: guide(
            crown: 0.04 ... 0.14,
            chin: 0.75 ... 0.94,
            measurement: "Head height: 32–36 mm",
            source: "Ministry of Foreign Affairs of Japan",
            url: "https://www.mofa.go.jp/mofaj/toko/passport/ic_photo.html"
        ),
        .passportSouthKorea: guide(
            crown: 0.06 ... 0.14,
            chin: 0.77 ... 0.94,
            measurement: "Head height: 32–36 mm",
            source: "Korea Passport Office",
            url: "https://www.passport.go.kr/home/kor/contents.do?menuPos=32"
        ),
        .passportAustralia: guide(
            crown: 0.05 ... 0.14,
            chin: 0.76 ... 0.92,
            measurement: "Face height: 32–36 mm",
            source: "Australian Passport Office",
            url: "https://www.passports.gov.au/getting-passport-how-it-works/photo-guidelines"
        ),
        .passportSingaporePrint: guide(
            crown: 0.07 ... 0.17,
            chin: 0.63 ... 0.85,
            measurement: "Face height: 25–35 mm",
            source: "Singapore Immigration and Checkpoints Authority",
            url: "https://www.ica.gov.sg/photo-guidelines"
        ),
        .passportSingaporeDigital: guide(
            crown: 0.07 ... 0.17,
            chin: 0.63 ... 0.85,
            measurement: "Face height: 25–35 mm",
            source: "Singapore Immigration and Checkpoints Authority",
            url: "https://www.ica.gov.sg/photo-guidelines"
        ),
        .passportNewZealandPrint: guide(
            crown: 0.05 ... 0.14,
            chin: 0.76 ... 0.92,
            measurement: "Head height: follow the online photo checker",
            source: "New Zealand Passports",
            url: "https://www.passports.govt.nz/passport-photos/passport-photo-requirements/"
        ),
        .passportNewZealandDigital: guide(
            crown: 0.05 ... 0.14,
            chin: 0.76 ... 0.92,
            measurement: "Head height: follow the online photo checker",
            source: "New Zealand Passports",
            url: "https://www.passports.govt.nz/passport-photos/passport-photo-requirements/"
        )
    ] as [Self: PassportGuide?]).compactMapValues
    {
        $0
    }
}
