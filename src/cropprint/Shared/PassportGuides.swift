import Foundation
import SwiftUI

struct PassportGuide {
    let crownBand: ClosedRange<CGFloat>
    let chinBand: ClosedRange<CGFloat>
    let measurement: String
    let sourceName: String
    let sourceURL: URL
}

extension CropPreset {
    var passportGuide: PassportGuide? {
        switch self {
        case .passportIndia:
            guide(crown: 0.07...0.16, chin: 0.63...0.84, measurement: "Head height: 25–35 mm", source: "Passport Seva, India", url: "https://www.passportindia.gov.in/AppOnlineProject/pdf/Photograph_Guidelines.pdf")
        case .passportUS:
            guide(crown: 0.08...0.18, chin: 0.58...0.76, measurement: "Head height: 1–1⅜ inches", source: "U.S. Department of State", url: "https://travel.state.gov/content/travel/en/passports/how-apply/photos.html")
        case .passportCanada:
            guide(crown: 0.14...0.22, chin: 0.58...0.72, measurement: "Face height: 31–36 mm", source: "Government of Canada", url: "https://www.canada.ca/en/immigration-refugees-citizenship/services/canadian-passports/photos.html")
        case .passportEurope:
            guide(crown: 0.05...0.14, chin: 0.76...0.92, measurement: "Common guide: head height about 32–36 mm", source: "European Commission", url: "https://home-affairs.ec.europa.eu/policies/schengen-borders-and-visa/document-security_en")
        case .passportUK:
            guide(crown: 0.07...0.16, chin: 0.71...0.91, measurement: "Head height: 29–34 mm", source: "GOV.UK", url: "https://www.gov.uk/photos-for-passports")
        case .passportChina:
            guide(crown: 0.06...0.11, chin: 0.64...0.80, measurement: "Head height: 28–33 mm", source: "Chinese consular guidance", url: "http://cs.mfa.gov.cn/zggmcg/ppp/hz/zhengjian/202007/t20200720_961088.shtml")
        case .passportJapan:
            guide(crown: 0.04...0.14, chin: 0.75...0.94, measurement: "Head height: 32–36 mm", source: "Ministry of Foreign Affairs of Japan", url: "https://www.mofa.go.jp/mofaj/toko/passport/ic_photo.html")
        case .passportSouthKorea:
            guide(crown: 0.06...0.14, chin: 0.77...0.94, measurement: "Head height: 32–36 mm", source: "Korea Passport Office", url: "https://www.passport.go.kr/home/kor/contents.do?menuPos=32")
        case .passportAustralia:
            guide(crown: 0.05...0.14, chin: 0.76...0.92, measurement: "Face height: 32–36 mm", source: "Australian Passport Office", url: "https://www.passports.gov.au/getting-passport-how-it-works/photo-guidelines")
        case .passportSingaporePrint, .passportSingaporeDigital:
            guide(crown: 0.07...0.17, chin: 0.63...0.85, measurement: "Face height: 25–35 mm", source: "Singapore Immigration and Checkpoints Authority", url: "https://www.ica.gov.sg/photo-guidelines")
        case .passportNewZealandPrint, .passportNewZealandDigital:
            guide(crown: 0.05...0.14, chin: 0.76...0.92, measurement: "Head height: follow the online photo checker", source: "New Zealand Passports", url: "https://www.passports.govt.nz/passport-photos/passport-photo-requirements/")
        default:
            nil
        }
    }

    private func guide(
        crown: ClosedRange<CGFloat>,
        chin: ClosedRange<CGFloat>,
        measurement: String,
        source: String,
        url: String
    ) -> PassportGuide? {
        guard let sourceURL = URL(string: url) else { return nil }
        return PassportGuide(
            crownBand: crown,
            chinBand: chin,
            measurement: measurement,
            sourceName: source,
            sourceURL: sourceURL
        )
    }
}

struct PassportGuideOverlay: View {
    let guide: PassportGuide

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                guideBand(
                    title: "Top of head",
                    range: guide.crownBand,
                    size: proxy.size
                )
                guideBand(
                    title: "Chin",
                    range: guide.chinBand,
                    size: proxy.size
                )

                Rectangle()
                    .fill(.yellow.opacity(0.7))
                    .frame(width: 1, height: proxy.size.height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                Text(guide.measurement)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.yellow.opacity(0.85), in: Capsule())
                    .padding(8)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func guideBand(
        title: String,
        range: ClosedRange<CGFloat>,
        size: CGSize
    ) -> some View {
        let height = max(2, (range.upperBound - range.lowerBound) * size.height)
        let centerY = (range.lowerBound + range.upperBound) * size.height / 2
        return ZStack(alignment: .trailing) {
            Rectangle()
                .fill(.yellow.opacity(0.24))
            Rectangle()
                .stroke(.yellow.opacity(0.95), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.yellow.opacity(0.85), in: Capsule())
                .padding(.trailing, 5)
        }
        .frame(width: size.width, height: height)
        .position(x: size.width / 2, y: centerY)
    }
}
