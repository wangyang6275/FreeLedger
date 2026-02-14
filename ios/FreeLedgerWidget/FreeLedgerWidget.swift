import WidgetKit
import SwiftUI

struct FreeLedgerWidgetEntryView: View {
    var entry: FreeLedgerEntry
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

struct FreeLedgerWidget: Widget {
    let kind: String = "FreeLedgerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FreeLedgerTimelineProvider()) { entry in
            FreeLedgerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("FreeLedger")
        .description(String(localized: "widget_description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct FreeLedgerWidgetBundle: WidgetBundle {
    var body: some Widget {
        FreeLedgerWidget()
    }
}
