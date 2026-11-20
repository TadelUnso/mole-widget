import Foundation

/// Shared widget settings (UserDefaults keys and bounds).
public enum WidgetSettings {
    // MARK: - Position / size

    /// Pins the widget: blocks both dragging and resizing.
    public static let positionLockedKey = "positionLocked"

    /// User-adjustable widget width (points).
    public static let widgetWidthKey = "widgetWidth"

    /// Below this width the longest text rows start wrapping.
    public static let minWidth: Double = 490
    public static let maxWidth: Double = 1200
    public static let defaultWidth: Double = 520

    /// One-click width presets offered in Settings.
    public static let widthPresets: [(label: String, width: Double)] = [
        ("Compact", 520),
        ("Medium", 640),
        ("Wide", 760),
        ("Extra Wide", 880),
        ("Huge", 1040),
        ("Maximum", 1200),
    ]

    public static func clampWidth(_ width: Double) -> Double {
        min(max(width, minWidth), maxWidth)
    }

    // MARK: - Columns

    /// How many section columns the widget grid uses.
    public enum ColumnMode: String {
        /// Two columns, switching to three once the widget is wide enough.
        case auto
        case two
        case three
    }

    public static let columnModeKey = "columnMode"
    public static let defaultColumnMode: ColumnMode = .auto

    /// Narrowest width at which three columns fit without the longest rows
    /// wrapping (same per-column room as two columns at `minWidth`).
    public static let threeColumnMinWidth: Double = 760

    public static func resolveColumnMode(_ raw: String?) -> ColumnMode {
        raw.flatMap(ColumnMode.init(rawValue:)) ?? defaultColumnMode
    }

    /// Number of grid columns for the given mode at the given widget width.
    public static func columnCount(mode: ColumnMode, width: Double) -> Int {
        switch mode {
        case .two:   return 2
        case .three: return 3
        case .auto:  return clampWidth(width) >= threeColumnMinWidth ? 3 : 2
        }
    }

    /// Width the widget is actually laid out at: the stored width, clamped,
    /// and widened to `threeColumnMinWidth` when three columns are forced.
    public static func effectiveWidth(stored: Double, mode: ColumnMode) -> Double {
        let width = clampWidth(stored)
        return mode == .three ? max(width, threeColumnMinWidth) : width
    }

    // MARK: - Background opacity

    public static let backgroundOpacityKey = "backgroundOpacity"
    public static let defaultOpacity: Double = 0.92

    /// Clamps opacity to the allowed range [0.3, 1.0].
    public static func clampOpacity(_ opacity: Double) -> Double {
        min(max(opacity, 0.3), 1.0)
    }

    // MARK: - Refresh rate

    public static let refreshIntervalKey = "refreshInterval"
    public static let defaultRefreshInterval: Double = 2.0

    // MARK: - Font

    /// Base font size in points. Picker offers 11 / 12 / 14 / 16.
    public static let fontSizeKey = "fontSize"
    public static let defaultFontSize: Double = 12

    /// Clamps the font size to the supported range [11, 16].
    public static func clampFontSize(_ size: Double) -> Double {
        min(max(size, 11), 16)
    }

    /// Font design: monospaced (aligned columns) or the native system face.
    public enum FontStyle: String {
        case monospaced
        case system
    }

    public static let fontStyleKey = "fontStyle"

    /// Default font style: the native system face reads more like a first-party
    /// macOS widget; users who prefer aligned columns can switch to monospaced.
    public static let defaultFontStyle: FontStyle = .system

    /// Resolves a stored raw value into a `FontStyle`, defaulting to
    /// `defaultFontStyle` for absent or unrecognized values.
    public static func resolveFontStyle(_ raw: String?) -> FontStyle {
        raw.flatMap(FontStyle.init(rawValue:)) ?? defaultFontStyle
    }

    // MARK: - Menu bar metrics

    /// Live metrics shown as text in the menu bar. All on by default so the menu
    /// bar shows a full readout out of the box; a metric with no data (e.g.
    /// battery temperature on a desktop Mac) is simply omitted from the text.
    public static let menuBarShowCPUKey     = "menuBarShowCPU"
    public static let menuBarShowMemoryKey  = "menuBarShowMemory"
    public static let menuBarShowTempKey    = "menuBarShowTemp"
    public static let menuBarShowNetworkKey = "menuBarShowNetwork"
    public static let menuBarShowDiskKey    = "menuBarShowDisk"

    // CPU/Memory/Temp on by default (the built-in readout); the rest are
    // opt-in so the menu bar stays compact until the user asks for more.
    // Network/Disk each show both directions stacked in one column.
    public static let defaultMenuBarShowCPU     = true
    public static let defaultMenuBarShowMemory  = true
    public static let defaultMenuBarShowTemp    = true
    public static let defaultMenuBarShowNetwork = false
    public static let defaultMenuBarShowDisk    = false

    // MARK: - Section visibility

    public static let showHeaderKey    = "showHeader"
    public static let showCPUKey       = "showCPU"
    public static let showMemoryKey    = "showMemory"
    public static let showDiskKey      = "showDisk"
    public static let showPowerKey     = "showPower"
    public static let showNetworkKey   = "showNetwork"
    public static let showProcessesKey = "showProcesses"

    // MARK: - Desktop visibility

    /// Whether the widget window is shown on the desktop. Hiding it keeps the
    /// app and its menu bar icon running so the widget can be summoned again.
    public static let widgetVisibleKey = "widgetVisible"
    public static let defaultVisible: Bool = true

    /// Resolves desktop visibility from the given defaults. An absent key reads
    /// as `defaultVisible` (visible); `UserDefaults.bool(forKey:)` on its own
    /// returns false for an absent key, which would wrongly start the widget
    /// hidden on a fresh install.
    public static func isVisible(in defaults: UserDefaults) -> Bool {
        defaults.object(forKey: widgetVisibleKey) == nil
            ? defaultVisible
            : defaults.bool(forKey: widgetVisibleKey)
    }
}
