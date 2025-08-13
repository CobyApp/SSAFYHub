import WidgetKit
import SwiftUI
import SharedModels

#Preview(as: .systemSmall) {
    SSAFYHubATypeWidget()
} timeline: {
    SSAFYHubTimelineEntry(
        date: Date(),
        menu: SharedModels.Menu(
            id: UUID().uuidString,
            date: Date(),
            campus: SharedModels.Campus.daejeon,
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
        menu: SharedModels.Menu(
            id: UUID().uuidString,
            date: Date(),
            campus: SharedModels.Campus.daejeon,
            itemsA: ["김치찌개", "제육볶음", "미역국"],
            itemsB: ["된장찌개", "불고기", "계란국"],
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}
