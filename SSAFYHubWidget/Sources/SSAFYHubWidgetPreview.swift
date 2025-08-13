import WidgetKit
import SwiftUI

#Preview(as: .systemSmall) {
    SSAFYHubATypeWidget()
} timeline: {
    SSAFYHubTimelineEntry(
        date: Date(),
        menu: Menu(
            id: UUID().uuidString,
            date: Date(),
            campus: .daejeon,
            itemsA: ["김치찌개", "제육볶음", "미역국"],
            itemsB: ["된장찌개", "불고기", "계란국"],
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}

#Preview(as: .systemMedium) {
    SSAFYHubBTypeWidget()
} timeline: {
    SSAFYHubTimelineEntry(
        date: Date(),
        menu: Menu(
            id: UUID().uuidString,
            date: Date(),
            campus: .daejeon,
            itemsA: ["김치찌개", "제육볶음", "미역국"],
            itemsB: ["된장찌개", "불고기", "계란국"],
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}
