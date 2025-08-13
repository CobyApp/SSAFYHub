import WidgetKit
import SwiftUI

struct SSAFYHubBTypeWidget: Widget {
    let kind: String = "SSAFYHubBTypeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SSAFYHubTimelineProvider()) { entry in
            SSAFYHubBTypeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("B타입 식단")
        .description("오늘의 B타입 식단을 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SSAFYHubBTypeWidgetEntryView: View {
    var entry: SSAFYHubTimelineEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("B타입")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 메뉴 내용
            if let menu = entry.menu, !menu.itemsB.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(menu.itemsB.prefix(3), id: \.self) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.green)
                                .frame(width: 4, height: 4)
                            
                            Text(item)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                    }
                    
                    if menu.itemsB.count > 3 {
                        Text("외 \(menu.itemsB.count - 3)개")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("오늘은 B타입 메뉴가 없습니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
