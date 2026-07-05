import Foundation
import Testing
@testable import MoleWidgetCore

@Suite struct MenuBarTextTests {
    @Test func allTogglesOff_returnsNil() {
        #expect(MenuBarText.compose(
            cpuFraction: 0.5, memFraction: 0.5, batteryTempC: 30,
            showCPU: false, showMemory: false, showTemp: false
        ) == nil)
    }

    @Test func singleMetric_cpuOnly() {
        #expect(MenuBarText.compose(
            cpuFraction: 0.42, memFraction: nil, batteryTempC: nil,
            showCPU: true, showMemory: false, showTemp: false
        ) == "CPU 42%")
    }

    @Test func allThree() {
        let text = MenuBarText.compose(
            cpuFraction: 0.423, memFraction: 0.34, batteryTempC: 31.4,
            showCPU: true, showMemory: true, showTemp: true
        )
        #expect(text == "CPU 42%  MEM 34%  TEMP 31°")
    }

    @Test func enabledButNilData_showsPlaceholders() {
        #expect(MenuBarText.compose(
            cpuFraction: nil, memFraction: nil, batteryTempC: nil,
            showCPU: true, showMemory: true, showTemp: true
        ) == "CPU --  MEM --  TEMP --")
    }

    @Test func cpuPercent_rounds() {
        #expect(MenuBarText.compose(
            cpuFraction: 0.005, memFraction: nil, batteryTempC: nil,
            showCPU: true, showMemory: false, showTemp: false
        ) == "CPU 1%")
        #expect(MenuBarText.compose(
            cpuFraction: 0.004, memFraction: nil, batteryTempC: nil,
            showCPU: true, showMemory: false, showTemp: false
        ) == "CPU 0%")
    }

    @Test func tempOnly_rounds() {
        #expect(MenuBarText.compose(
            cpuFraction: nil, memFraction: nil, batteryTempC: 30.6,
            showCPU: false, showMemory: false, showTemp: true
        ) == "TEMP 31°")
    }
}
