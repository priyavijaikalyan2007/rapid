import SwiftUI

struct PhotoAdjustmentEditor: View {
    @Binding var settings: PhotoAdjustmentSettings
    let allowsBackgroundRemoval: Bool
    let isPassportPhoto: Bool
    let isProcessing: Bool
    var showsDoneButton = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            if allowsBackgroundRemoval {
                Section("Background") {
                    Picker("Replace background", selection: $settings.background) {
                        ForEach(ReplacementBackground.allCases) { background in
                            Text(background.rawValue).tag(background)
                        }
                    }

                    Text("Person separation runs on this device. The photo does not leave the device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isPassportPhoto && settings.background != .original {
                        Label(
                            "Some passport authorities reject digitally replaced backgrounds. Check the current official rules before submission.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }
            }

            Section("Light and color") {
                adjustmentSlider("Exposure", value: $settings.exposure, range: -2...2)
                adjustmentSlider("Contrast", value: $settings.contrast, range: 0.5...1.5)
                adjustmentSlider("Highlights", value: $settings.highlights, range: -1...1)
                adjustmentSlider("Shadows", value: $settings.shadows, range: -1...1)
                adjustmentSlider("Saturation", value: $settings.saturation, range: 0...2)
                adjustmentSlider("Hue", value: $settings.hue, range: -180...180, suffix: "°")
                adjustmentSlider("Sharpness", value: $settings.sharpness, range: 0...1)
            }

            Section("Straighten") {
                adjustmentSlider("Angle", value: $settings.angle, range: -15...15, suffix: "°")
                Text("Angle adjustment enlarges the photo enough to avoid empty corners.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isPassportPhoto && settings.hasToneChanges {
                Section {
                    Label(
                        "Passport authorities can reject altered photos. Use edits only to correct the captured image.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }

            Section {
                Button("Reset Photo Edits", role: .destructive) {
                    settings = PhotoAdjustmentSettings()
                }
                .disabled(settings.isDefault)

                if isProcessing {
                    HStack {
                        ProgressView()
                        Text("Applying local photo edits…")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Photo Adjustments")
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func adjustmentSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String = ""
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(1))) + suffix)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }
}
