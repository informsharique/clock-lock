import SwiftUI

/// Preferences UI — clock style picker + background picker.
/// Uses adaptive system colors so it looks correct in both Light and Dark mode.
struct PreferencesView: View {
    @ObservedObject var settings: ClockSettings
    let dismiss: () -> Void

    @State private var selectedClock: ClockStyle
    @State private var selectedBackground: BackgroundStyle

    init(settings: ClockSettings, dismiss: @escaping () -> Void) {
        self.settings = settings
        self.dismiss = dismiss
        _selectedClock      = State(initialValue: settings.clockStyle)
        _selectedBackground = State(initialValue: settings.backgroundStyle)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 580, height: 400)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text("ClockLock")
                    .font(.headline)
                Text("Choose a clock face and background")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionLabel(title: "Clock Face", icon: "clock")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(ClockStyle.allCases) { style in
                            ClockStyleCard(
                                style: style,
                                isSelected: selectedClock == style,
                                onTap: { selectedClock = style }
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.bottom, 4)
                }

                Divider()

                sectionLabel(title: "Background", icon: "photo.on.rectangle.angled")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(BackgroundStyle.allCases) { style in
                            BackgroundStyleCard(
                                style: style,
                                isSelected: selectedBackground == style,
                                onTap: { selectedBackground = style }
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.bottom, 4)
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func sectionLabel(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("Settings take effect immediately on preview.")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.escape)
            Button("Apply") {
                settings.clockStyle      = selectedClock
                settings.backgroundStyle = selectedBackground
                settings.savePreferences()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Clock Style Card
// Uses purely static gradient swatches + a declarative clock-hand icon.
// No Canvas, no timers, no clock face rendering — eliminates all rendering overhead
// when the Options window is open.

struct ClockStyleCard: View {
    let style: ClockStyle
    let isSelected: Bool
    let onTap: () -> Void

    private let size: CGFloat = 90

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(clockGradient)
                    .frame(width: size, height: size)

                clockHandIcon

                if isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                        .frame(width: size, height: size)
                }
            }
            Text(style.displayName)
                .font(.caption)
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .onTapGesture { onTap() }
    }

    private var clockGradient: LinearGradient {
        switch style {
        case .spectrum:
            return LinearGradient(
                colors: [Color(hue: 0.00, saturation: 1, brightness: 0.7),
                         Color(hue: 0.33, saturation: 1, brightness: 0.6),
                         Color(hue: 0.66, saturation: 1, brightness: 0.7)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neon:
            return LinearGradient(
                colors: [.black, Color(hue: 0.51, saturation: 1, brightness: 0.45)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sunrise:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.9, blue: 0.4),
                         Color(red: 0.8, green: 0.2, blue: 0.5),
                         Color(red: 0.1, green: 0.03, blue: 0.4)],
                startPoint: .top, endPoint: .bottom)
        case .void:
            return LinearGradient(
                colors: [Color(white: 0.22), Color(red: 0.06, green: 0.04, blue: 0.28)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .crystal:
            return LinearGradient(
                colors: [Color(hue: 0.60, saturation: 0.9, brightness: 0.60),
                         Color(hue: 0.75, saturation: 0.9, brightness: 0.50),
                         Color(hue: 0.88, saturation: 0.8, brightness: 0.40)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // Declarative (non-Canvas) clock hand icon — no animation overhead
    @ViewBuilder
    private var clockHandIcon: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1.2)
                .frame(width: size * 0.70, height: size * 0.70)
            Rectangle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 2.0, height: size * 0.20)
                .offset(y: -size * 0.08)
                .rotationEffect(.degrees(-40))
            Rectangle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 1.5, height: size * 0.27)
                .offset(y: -size * 0.11)
                .rotationEffect(.degrees(60))
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
        }
    }
}

// MARK: - Background Style Card

struct BackgroundStyleCard: View {
    let style: BackgroundStyle
    let isSelected: Bool
    let onTap: () -> Void

    private let cardW: CGFloat = 115
    private let cardH: CGFloat = 72

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(bgGradient)
                    .frame(width: cardW, height: cardH)

                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                        .frame(width: cardW, height: cardH)
                }
            }
            Text(style.displayName)
                .font(.caption)
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .onTapGesture { onTap() }
    }

    private var bgGradient: LinearGradient {
        switch style {
        case .aurora:
            return LinearGradient(
                colors: [Color(hue: 0.47, saturation: 0.9, brightness: 0.5),
                         Color(hue: 0.72, saturation: 0.8, brightness: 0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .nebula:
            return LinearGradient(
                colors: [Color(red: 0.10, green: 0.04, blue: 0.25),
                         Color(red: 0.22, green: 0.05, blue: 0.35),
                         Color(red: 0.01, green: 0.01, blue: 0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .wave:
            return LinearGradient(
                colors: [Color(hue: 0.58, saturation: 0.8, brightness: 0.45),
                         Color(hue: 0.70, saturation: 0.8, brightness: 0.20)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .geometric:
            return LinearGradient(
                colors: [Color(hue: 0.64, saturation: 0.85, brightness: 0.35),
                         Color(hue: 0.72, saturation: 0.80, brightness: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ember:
            return LinearGradient(
                colors: [Color(red: 0.55, green: 0.10, blue: 0.01),
                         Color(red: 0.15, green: 0.03, blue: 0.01)],
                startPoint: .top, endPoint: .bottom)
        case .constellation:
            return LinearGradient(
                colors: [Color(red: 0.02, green: 0.05, blue: 0.18),
                         Color(red: 0.10, green: 0.02, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
