import SwiftUI

/// Full-width header row showing the composite health score and static system info.
///
/// Example output: `Health ● 94 · Apple M3 Pro · 16.0 GB · macOS 15.4 · up 5h 36m`
public struct HeaderView: View {
    let info: SystemInfoSnapshot?
    let score: Int

    public init(info: SystemInfoSnapshot?, score: Int) {
        self.info = info
        self.score = score
    }

    /// Color of the health dot: green ≥ 80, yellow ≥ 50, red < 50.
    private var dotColor: Color {
        if score >= 80 { return Theme.accent }
        if score >= 50 { return Theme.warning }
        return Theme.danger
    }

    public var body: some View {
        HStack(spacing: 4) {
            Text("Health")
                .foregroundStyle(Theme.header)
                .fontWeight(.bold)

            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)

            Text("\(score)")
                .foregroundStyle(Theme.text)

            if let info {
                Text("·")
                    .foregroundStyle(Theme.dim)

                Text(
                    "\(info.chip) · \(Fmt.gigabytes(info.ramBytes)) · macOS \(info.osVersion) · \(SystemInfoSnapshot.formatUptime(info.uptime))"
                )
                .foregroundStyle(Theme.dim)
            }

            Spacer()
        }
    }
}
