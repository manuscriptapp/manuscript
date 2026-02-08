import SwiftUI

enum ThemeAppearance: String, Codable, CaseIterable {
    case system
    case light
    case dark

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum ThemeMaterialStyle: String, Codable, CaseIterable {
    case none
    case ultraThin
    case thin
    case regular
}

struct ThemeMaterial: Codable, Equatable {
    let style: ThemeMaterialStyle
    let opacity: Double
}

struct ThemePalette: Codable, Equatable {
    let background: String
    let groupedBackground: String
    let surface: String
    let text: String
    let secondaryText: String
    let accent: String
}

struct AppTheme: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let appearance: ThemeAppearance
    let usesSystemColors: Bool
    let material: ThemeMaterial
    let palette: ThemePalette

    var preferredColorScheme: ColorScheme? {
        appearance.preferredColorScheme
    }

    var backgroundColor: Color {
        color(for: palette.background, fallback: .systemBackground)
    }

    var groupedBackgroundColor: Color {
        color(for: palette.groupedBackground, fallback: .systemGroupedBackground)
    }

    var surfaceColor: Color {
        color(for: palette.surface, fallback: .systemGray5)
    }

    var textColor: Color {
        color(for: palette.text, fallback: .primary)
    }

    var secondaryTextColor: Color {
        color(for: palette.secondaryText, fallback: .secondary)
    }

    var accentColor: Color {
        color(for: palette.accent, fallback: .accentColor)
    }

    var overlayMaterial: Material? {
        switch material.style {
        case .none:
            return nil
        case .ultraThin:
            return .ultraThinMaterial
        case .thin:
            return .thinMaterial
        case .regular:
            return .regularMaterial
        }
    }

    private func color(for hex: String, fallback: Color) -> Color {
        if usesSystemColors {
            return fallback
        }
        return Color(hex: hex) ?? fallback
    }

    static let system = AppTheme(
        id: "system",
        name: "System",
        appearance: .system,
        usesSystemColors: true,
        material: ThemeMaterial(style: .ultraThin, opacity: 0.35),
        palette: ThemePalette(
            background: "#FFFFFF",
            groupedBackground: "#F2F2F7",
            surface: "#F2F2F7",
            text: "#000000",
            secondaryText: "#3C3C43",
            accent: "#0A84FF"
        )
    )

    static let solarized = AppTheme(
        id: "solarized",
        name: "Solarized",
        appearance: .light,
        usesSystemColors: false,
        material: ThemeMaterial(style: .ultraThin, opacity: 0.12),
        palette: ThemePalette(
            background: "#FDF6E3",
            groupedBackground: "#EEE8D5",
            surface: "#E7DFC8",
            text: "#657B83",
            secondaryText: "#93A1A1",
            accent: "#268BD2"
        )
    )

    static let solarizedDark = AppTheme(
        id: "solarized-dark",
        name: "Solarized Dark",
        appearance: .dark,
        usesSystemColors: false,
        material: ThemeMaterial(style: .thin, opacity: 0.16),
        palette: ThemePalette(
            background: "#002B36",
            groupedBackground: "#073642",
            surface: "#0B3A47",
            text: "#93A1A1",
            secondaryText: "#839496",
            accent: "#B58900"
        )
    )

    static let defaultThemes: [AppTheme] = [
        .system,
        .solarized,
        .solarizedDark
    ]

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case appearance
        case usesSystemColors
        case material
        case palette
    }

    init(
        id: String,
        name: String,
        appearance: ThemeAppearance,
        usesSystemColors: Bool,
        material: ThemeMaterial,
        palette: ThemePalette
    ) {
        self.id = id
        self.name = name
        self.appearance = appearance
        self.usesSystemColors = usesSystemColors
        self.material = material
        self.palette = palette
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        appearance = try container.decode(ThemeAppearance.self, forKey: .appearance)
        usesSystemColors = try container.decode(Bool.self, forKey: .usesSystemColors)
        palette = try container.decode(ThemePalette.self, forKey: .palette)
        material = try container.decodeIfPresent(ThemeMaterial.self, forKey: .material)
            ?? ThemeMaterial(style: .ultraThin, opacity: 0.2)
    }
}

final class ThemeManager: ObservableObject {
    @Published private(set) var themes: [AppTheme] = []
    @Published var selectedThemeID: String {
        didSet {
            UserDefaults.standard.set(selectedThemeID, forKey: Self.selectedThemeKey)
        }
    }

    let themesDirectoryURL: URL

    private let fileManager: FileManager
    private static let selectedThemeKey = "selectedThemeID"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let savedTheme = UserDefaults.standard.string(forKey: Self.selectedThemeKey)
        self.selectedThemeID = savedTheme ?? AppTheme.system.id
        self.themesDirectoryURL = ThemeManager.makeThemesDirectoryURL(fileManager: fileManager)
        installDefaultThemesIfNeeded()
        loadThemes()
    }

    var selectedTheme: AppTheme {
        themes.first { $0.id == selectedThemeID } ?? AppTheme.system
    }

    func reloadThemes() {
        loadThemes()
    }

    private func loadThemes() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: themesDirectoryURL,
            includingPropertiesForKeys: nil
        ) else {
            themes = AppTheme.defaultThemes
            return
        }

        var loadedThemes: [AppTheme] = []
        for file in files where file.pathExtension.lowercased() == "json" {
            guard let data = try? Data(contentsOf: file) else { continue }
            if let theme = try? JSONDecoder().decode(AppTheme.self, from: data) {
                loadedThemes.append(theme)
            }
        }

        if loadedThemes.isEmpty {
            loadedThemes = AppTheme.defaultThemes
        }

        let uniqueThemes = Dictionary(grouping: loadedThemes, by: \.id)
            .compactMap { $0.value.first }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        themes = uniqueThemes
        if themes.first(where: { $0.id == selectedThemeID }) == nil {
            selectedThemeID = AppTheme.system.id
        }
    }

    private func installDefaultThemesIfNeeded() {
        do {
            try fileManager.createDirectory(at: themesDirectoryURL, withIntermediateDirectories: true)
        } catch {
            print("Failed to create themes directory: \(error)")
        }

        for theme in AppTheme.defaultThemes {
            let fileURL = themesDirectoryURL.appendingPathComponent("\(theme.id).json")
            guard !fileManager.fileExists(atPath: fileURL.path) else { continue }
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(theme)
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("Failed to write theme \(theme.name): \(error)")
            }
        }
    }

    private static func makeThemesDirectoryURL(fileManager: FileManager) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let baseURL = appSupport ?? fileManager.temporaryDirectory
        return baseURL
            .appendingPathComponent("Manuscript", isDirectory: true)
            .appendingPathComponent("Themes", isDirectory: true)
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.system
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

extension View {
    func applyAppTheme(_ theme: AppTheme) -> some View {
        let themedView = self
            .environment(\.appTheme, theme)
            .tint(theme.accentColor)

        guard let preferredScheme = theme.preferredColorScheme else {
            return AnyView(themedView)
        }

        return AnyView(themedView.preferredColorScheme(preferredScheme))
    }
}

struct AppThemeContainer<Content: View>: View {
    let theme: AppTheme
    let content: Content

    init(theme: AppTheme, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.content = content()
    }

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            if let overlayMaterial = theme.overlayMaterial, theme.material.opacity > 0 {
                Rectangle()
                    .fill(overlayMaterial)
                    .opacity(theme.material.opacity)
                    .ignoresSafeArea()
            }
            content
        }
        .applyAppTheme(theme)
        .foregroundStyle(theme.textColor)
    }
}
