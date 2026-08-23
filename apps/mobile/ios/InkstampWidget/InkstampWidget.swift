import SwiftUI
import WidgetKit

private let appGroup = "group.com.inkstamp.app"

struct InkstampEntry: TimelineEntry {
    let date: Date
    let senderName: String
    let imagePath: String?
    let stampId: String?
}

struct InkstampProvider: TimelineProvider {
    func placeholder(in context: Context) -> InkstampEntry {
        InkstampEntry(
            date: Date(),
            senderName: "Inkstamp",
            imagePath: nil,
            stampId: nil
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (InkstampEntry) -> Void
    ) {
        completion(readEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<InkstampEntry>) -> Void
    ) {
        completion(
            Timeline(
                entries: [readEntry()],
                policy: .after(Date().addingTimeInterval(15 * 60))
            )
        )
    }

    private func readEntry() -> InkstampEntry {
        let defaults = UserDefaults(suiteName: appGroup)
        return InkstampEntry(
            date: Date(),
            senderName: defaults?.string(forKey: "latest_sender") ?? "Inkstamp",
            imagePath: defaults?.string(forKey: "latest_thumbnail_path"),
            stampId: defaults?.string(forKey: "latest_stamp_id")
        )
    }
}

struct InkstampWidgetView: View {
    let entry: InkstampEntry

    var body: some View {
        ZStack {
            Color(red: 0.965, green: 0.941, blue: 0.906)
            VStack(spacing: 8) {
                if
                    let imagePath = entry.imagePath,
                    let image = UIImage(contentsOfFile: imagePath)
                {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    Image(systemName: "envelope.open")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color(red: 0.588, green: 0.710, blue: 0.792))
                }
                Text(entry.senderName)
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.133, green: 0.129, blue: 0.122))
                    .lineLimit(1)
            }
            .padding(10)
        }
        .widgetURL(
            entry.stampId.flatMap { URL(string: "inkstamp://stamp/\($0)") }
        )
    }
}

@main
struct InkstampWidget: Widget {
    let kind = "InkstampWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InkstampProvider()) { entry in
            InkstampWidgetView(entry: entry)
        }
        .configurationDisplayName("Latest Inkstamp")
        .description("See the latest stamp from your friends.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
