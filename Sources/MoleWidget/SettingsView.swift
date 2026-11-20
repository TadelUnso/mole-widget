import MoleWidgetCore
import ServiceManagement
import SwiftUI

/// Settings window: every widget preference in one place, grouped into tabs.
/// All values are `@AppStorage`-backed, so changes apply to the widget live —
/// the AppDelegate observes UserDefaults and resizes the window as needed.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gearshape") }
            AppearanceSettingsTab()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            SectionsSettingsTab()
                .tabItem { Label("Sections", systemImage: "square.grid.2x2") }
            MenuBarSettingsTab()
                .tabItem { Label("Menu Bar", systemImage: "menubar.rectangle") }
        }
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    @AppStorage(WidgetSettings.widgetVisibleKey) private var widgetVisible = WidgetSettings.defaultVisible
    @AppStorage(WidgetSettings.positionLockedKey) private var positionLocked = false
    @AppStorage(WidgetSettings.refreshIntervalKey)
    private var refreshInterval = WidgetSettings.defaultRefreshInterval
    @AppStorage(WidgetSettings.showKofiKey) private var showKofi = WidgetSettings.defaultShowKofi

    var body: some View {
        Form {
            Section {
                LaunchAtLoginToggle()
                Toggle("Show widget on desktop", isOn: $widgetVisible)
                Toggle("Lock position and size", isOn: $positionLocked)
            }
            Section {
                // Tags are exact Double literals so the Picker matches the stored value.
                Picker("Refresh rate", selection: $refreshInterval) {
                    Text("1 second").tag(1.0)
                    Text("2 seconds").tag(2.0)
                    Text("5 seconds").tag(5.0)
                }
            }
            Section {
                Toggle("Show Ko-fi button", isOn: $showKofi)
            } footer: {
                Text("The small “Ko-fi | Support” badge in the widget title bar.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Appearance

private struct AppearanceSettingsTab: View {
    @AppStorage(WidgetSettings.widgetWidthKey) private var widgetWidth = WidgetSettings.defaultWidth
    @AppStorage(WidgetSettings.columnModeKey)
    private var columnMode = WidgetSettings.defaultColumnMode.rawValue
    @AppStorage(WidgetSettings.fontSizeKey) private var fontSize = WidgetSettings.defaultFontSize
    @AppStorage(WidgetSettings.fontStyleKey)
    private var fontStyle = WidgetSettings.defaultFontStyle.rawValue
    @AppStorage(WidgetSettings.backgroundOpacityKey)
    private var backgroundOpacity = WidgetSettings.defaultOpacity
    @AppStorage(WidgetSettings.cornerRadiusKey)
    private var cornerRadius = WidgetSettings.defaultCornerRadius

    private var resolvedMode: WidgetSettings.ColumnMode {
        WidgetSettings.resolveColumnMode(columnMode)
    }

    private var effectiveWidth: Double {
        WidgetSettings.effectiveWidth(stored: widgetWidth, mode: resolvedMode)
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Width") {
                    HStack {
                        Slider(
                            value: Binding(
                                get: { WidgetSettings.clampWidth(widgetWidth) },
                                set: { widgetWidth = $0.rounded() }
                            ),
                            in: WidgetSettings.minWidth ... WidgetSettings.maxWidth,
                            step: 10
                        )
                        Text("\(Int(effectiveWidth)) pt")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                LabeledContent("Presets") {
                    HStack(spacing: 4) {
                        ForEach(WidgetSettings.widthPresets, id: \.width) { preset in
                            Button(preset.label) { widgetWidth = preset.width }
                                .controlSize(.small)
                        }
                    }
                }
                Picker("Columns", selection: $columnMode) {
                    Text("Auto").tag(WidgetSettings.ColumnMode.auto.rawValue)
                    Text("2").tag(WidgetSettings.ColumnMode.two.rawValue)
                    Text("3").tag(WidgetSettings.ColumnMode.three.rawValue)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Size")
            } footer: {
                Text(columnsFooter).foregroundStyle(.secondary)
            }

            Section("Text") {
                Picker("Font size", selection: $fontSize) {
                    Text("Small").tag(11.0)
                    Text("Medium").tag(12.0)
                    Text("Large").tag(14.0)
                    Text("Extra Large").tag(16.0)
                }
                Picker("Font style", selection: $fontStyle) {
                    Text("System").tag(WidgetSettings.FontStyle.system.rawValue)
                    Text("Monospaced").tag(WidgetSettings.FontStyle.monospaced.rawValue)
                }
            }

            Section("Background") {
                LabeledContent("Corner radius") {
                    HStack {
                        Slider(
                            value: Binding(
                                get: { WidgetSettings.clampCornerRadius(cornerRadius) },
                                set: { cornerRadius = $0.rounded() }
                            ),
                            in: WidgetSettings.minCornerRadius ... WidgetSettings.maxCornerRadius,
                            step: 1
                        )
                        Text("\(Int(WidgetSettings.clampCornerRadius(cornerRadius))) pt")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                LabeledContent("Presets") {
                    HStack(spacing: 4) {
                        Button("Classic (\(Int(WidgetSettings.defaultCornerRadius)))") {
                            cornerRadius = WidgetSettings.defaultCornerRadius
                        }
                        Button("Like macOS widgets (\(Int(WidgetSettings.nativeCornerRadius)))") {
                            cornerRadius = WidgetSettings.nativeCornerRadius
                        }
                    }
                    .controlSize(.small)
                }
                // On macOS 26+ the widget uses Liquid Glass, which ignores opacity.
                if #unavailable(macOS 26) {
                    Picker("Opacity", selection: $backgroundOpacity) {
                        Text("100%").tag(1.0)
                        Text("92%").tag(0.92)
                        Text("85%").tag(0.85)
                        Text("70%").tag(0.7)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var columnsFooter: String {
        let threshold = Int(WidgetSettings.threeColumnMinWidth)
        switch resolvedMode {
        case .auto:
            return "Auto uses three columns from \(threshold) pt width. You can also drag the widget’s right edge."
        case .two:
            return "Always two columns. You can also drag the widget’s right edge."
        case .three:
            return "Three columns need at least \(threshold) pt, so narrower widths are widened."
        }
    }
}

// MARK: - Sections

private struct SectionsSettingsTab: View {
    @AppStorage(WidgetSettings.showHeaderKey)    private var showHeader    = true
    @AppStorage(WidgetSettings.showCPUKey)       private var showCPU       = true
    @AppStorage(WidgetSettings.showMemoryKey)    private var showMemory    = true
    @AppStorage(WidgetSettings.showDiskKey)      private var showDisk      = true
    @AppStorage(WidgetSettings.showPowerKey)     private var showPower     = true
    @AppStorage(WidgetSettings.showNetworkKey)   private var showNetwork   = true
    @AppStorage(WidgetSettings.showProcessesKey) private var showProcesses = true

    var body: some View {
        Form {
            Section {
                Toggle("Header (system info & health score)", isOn: $showHeader)
            }
            Section {
                Toggle("CPU",       isOn: $showCPU)
                Toggle("Memory",    isOn: $showMemory)
                Toggle("Disk",      isOn: $showDisk)
                Toggle("Power",     isOn: $showPower)
                Toggle("Network",   isOn: $showNetwork)
                Toggle("Processes", isOn: $showProcesses)
            } header: {
                Text("Metrics")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Menu bar

private struct MenuBarSettingsTab: View {
    @AppStorage(WidgetSettings.menuBarShowCPUKey)     private var showCPU     = WidgetSettings.defaultMenuBarShowCPU
    @AppStorage(WidgetSettings.menuBarShowMemoryKey)  private var showMemory  = WidgetSettings.defaultMenuBarShowMemory
    @AppStorage(WidgetSettings.menuBarShowTempKey)    private var showTemp    = WidgetSettings.defaultMenuBarShowTemp
    @AppStorage(WidgetSettings.menuBarShowNetworkKey) private var showNetwork = WidgetSettings.defaultMenuBarShowNetwork
    @AppStorage(WidgetSettings.menuBarShowDiskKey)    private var showDisk    = WidgetSettings.defaultMenuBarShowDisk

    var body: some View {
        Form {
            Section {
                Toggle("CPU",             isOn: $showCPU)
                Toggle("Memory",          isOn: $showMemory)
                Toggle("CPU temperature", isOn: $showTemp)
                Toggle("Network",         isOn: $showNetwork)
                Toggle("Disk",            isOn: $showDisk)
            } header: {
                Text("Live metrics in the menu bar")
            } footer: {
                Text("With everything off, the menu bar shows just the “M” icon.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Launch at login

/// "Launch at login" toggle backed by SMAppService (macOS 13+).
/// Registration only works when running as a proper .app bundle;
/// from a bare dev binary register() throws and the toggle reverts.
struct LaunchAtLoginToggle: View {
    @State private var enabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Toggle("Launch at login", isOn: Binding(
            get: { enabled },
            set: { newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                    enabled = newValue
                } catch {
                    // Keep the toggle in sync with reality on failure
                    enabled = SMAppService.mainApp.status == .enabled
                }
            }
        ))
    }
}
