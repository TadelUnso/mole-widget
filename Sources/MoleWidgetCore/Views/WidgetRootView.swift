import SwiftUI

/// Root widget view: a 2×2 grid of sections on a dark background
/// with a clickable lock button for position locking in the top-right corner.
public struct WidgetRootView: View {
    let store: MetricsStore

    @AppStorage(WidgetSettings.positionLockedKey) private var positionLocked = false

    /// Column width chosen so the total widget width
    /// (2 columns + column gap + padding ≈ 520pt) matches the width
    /// of a native macOS small + medium widget pair.
    private let columnWidth: CGFloat = 232

    public init(store: MetricsStore) {
        self.store = store
    }

    public var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 24, verticalSpacing: 16) {
            GridRow {
                CPUSectionView(snapshot: store.cpu)
                    .frame(width: columnWidth, alignment: .topLeading)
                MemorySectionView(snapshot: store.memory)
                    .frame(width: columnWidth, alignment: .topLeading)
            }
            GridRow {
                DiskSectionView(usage: store.diskUsage, io: store.diskIO)
                    .frame(width: columnWidth, alignment: .topLeading)
                PowerSectionView(snapshot: store.power)
                    .frame(width: columnWidth, alignment: .topLeading)
            }
        }
        .font(Theme.font)
        .padding(16)
        .background(
            Theme.background.opacity(0.92),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(alignment: .topTrailing) {
            lockButton
        }
    }

    private var lockButton: some View {
        Button {
            positionLocked.toggle()
        } label: {
            Image(systemName: positionLocked ? "lock.fill" : "lock.open")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(positionLocked ? Theme.warning : Theme.dim)
                .frame(width: 20, height: 20) // hit area slightly larger than the icon
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(6)
        .help(positionLocked
            ? "Position is locked — click to unlock"
            : "Click to lock the widget position")
    }
}
