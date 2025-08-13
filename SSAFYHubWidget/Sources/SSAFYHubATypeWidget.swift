import WidgetKit
import SwiftUI

struct SSAFYHubATypeWidget: Widget {
    let kind: String = "SSAFYHubATypeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SSAFYHubTimelineProvider()) { entry in
            SSAFYHubATypeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("A타입 식단")
        .description("오늘의 A타입 식단을 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SSAFYHubATypeWidgetEntryView: View {
    var entry: SSAFYHubTimelineEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("A타입")
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
            if let menu = entry.menu, !menu.itemsA.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(menu.itemsA.prefix(3), id: \.self) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.orange)
                                .frame(width: 4, height: 4)
                            
                            Text(item)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                    }
                    
                    if menu.itemsA.count > 3 {
                        Text("외 \(menu.itemsA.count - 3)개")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("오늘은 A타입 메뉴가 없습니다")
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
