import SwiftUI

/// Widget section: "● CPU ························" header + content.
public struct SectionView<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content

    public init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(icon).foregroundStyle(Theme.header)
                Text(title).bold().foregroundStyle(Theme.header)
                DottedLine()
            }
            content
        }
    }
}

/// Dotted filler line in the section header.
struct DottedLine: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(Theme.dim.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [1, 3]))
        }
        .frame(height: 10)
    }
}

/// Row with "label — bar — value" layout.
struct MetricRow: View {
    let label: String
    let fraction: Double
    let value: String
    var barColor: Color?

    init(label: String, fraction: Double, value: String, barColor: Color? = nil) {
        self.label = label
        self.fraction = fraction
        self.value = value
        self.barColor = barColor
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .foregroundStyle(Theme.text)
                .frame(width: 56, alignment: .leading)
            BarView(fraction: fraction, color: barColor)
            Text(value)
                .foregroundStyle(Theme.text)
                .frame(width: 56, alignment: .trailing)
        }
    }
}

/// Row with "label — text" layout, no bar.
struct TextRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .foregroundStyle(Theme.text)
                .frame(width: 56, alignment: .leading)
            Text(value)
                .foregroundStyle(Theme.text)
            Spacer(minLength: 0)
        }
    }
}
