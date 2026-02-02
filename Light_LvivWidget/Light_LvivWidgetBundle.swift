import WidgetKit
import SwiftUI

struct Light_LvivWidget: Widget {
    let kind: String = "Light_LvivWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PowerStatusProvider()) { entry in
            Light_LvivWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Power Status")
        .description("Track power outages for your selected group")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct Light_LvivWidgetEntryView: View {
    var entry: PowerStatusProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

@main
struct Light_LvivWidgetBundle: WidgetBundle {
    var body: some Widget {
        Light_LvivWidget()
    }
}
