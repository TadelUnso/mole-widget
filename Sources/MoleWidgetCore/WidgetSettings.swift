/// Shared widget settings (UserDefaults keys and bounds).
public enum WidgetSettings {
    /// Pins the widget: blocks both dragging and resizing.
    public static let positionLockedKey = "positionLocked"

    /// User-adjustable widget width (points).
    public static let widgetWidthKey = "widgetWidth"

    /// Below this width the longest text rows start wrapping.
    public static let minWidth: Double = 490
    public static let maxWidth: Double = 880
    public static let defaultWidth: Double = 520

    public static func clampWidth(_ width: Double) -> Double {
        min(max(width, minWidth), maxWidth)
    }
}
