import WidgetKit
import SwiftUI

struct ColorFuLedgerWidgetEntryView: View {
    var entry: ColorFuLedgerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct ColorFuLedgerWidget: Widget {
    let kind: String = "ColorFuLedgerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ColorFuLedgerTimelineProvider()) { entry in
            ColorFuLedgerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ColorFuLedger")
        .description(String(localized: "widget_description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct ColorFuLedgerWidgetBundle: WidgetBundle {
    var body: some Widget {
        ColorFuLedgerWidget()
    }
}
