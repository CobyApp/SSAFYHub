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
        .supportedFamilies([.systemSmall])
    }
}

struct SSAFYHubATypeWidgetEntryView: View {
    var entry: SSAFYHubTimelineEntry
    
    var body: some View {
        VStack {
            Spacer()
            
            // 메뉴 내용만 표시
            if let menu = entry.menu, !menu.itemsA.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(menu.itemsA, id: \.self) { item in
                        Text(item)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                Text("오늘은 A타입 메뉴가 없습니다")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            // A타입: 파란색 배경
            Color(red: 0.2, green: 0.6, blue: 1.0)
        }
    }
}
