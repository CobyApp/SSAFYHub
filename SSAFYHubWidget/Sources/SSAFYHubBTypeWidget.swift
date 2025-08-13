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
        .supportedFamilies([.systemSmall])
    }
}

struct SSAFYHubBTypeWidgetEntryView: View {
    var entry: SSAFYHubTimelineEntry
    
    var body: some View {
        VStack {
            Spacer()
            
            // 메뉴 내용만 표시
            if let menu = entry.menu, !menu.itemsB.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(menu.itemsB, id: \.self) { item in
                        Text(item)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                Text("오늘은 B타입 메뉴가 없습니다")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            // B타입: 초록색 배경
            Color(red: 0.2, green: 0.8, blue: 0.4)
        }
    }
}
