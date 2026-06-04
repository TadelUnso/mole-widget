import Testing
@testable import MoleWidgetCore

@Suite struct WidgetSettingsTests {
    @Test func clampWidth() {
        #expect(WidgetSettings.clampWidth(100) == WidgetSettings.minWidth)
        #expect(WidgetSettings.clampWidth(10_000) == WidgetSettings.maxWidth)
        #expect(WidgetSettings.clampWidth(600) == 600)
        #expect(WidgetSettings.clampWidth(WidgetSettings.minWidth) == WidgetSettings.minWidth)
        #expect(WidgetSettings.clampWidth(WidgetSettings.maxWidth) == WidgetSettings.maxWidth)
    }
}
