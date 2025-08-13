import WidgetKit
import SwiftUI
import SharedModels

#Preview(as: .systemSmall) {
    SSAFYHubATypeWidget()
} timeline: {
    SSAFYHubTimelineEntry(
        date: Date(),
        menu: MealMenu(
            id: UUID().uuidString,
            date: Date(),
            campus: Campus.daejeon,
            itemsA: ["김치찌개", "제육볶음", "미역국"],
            itemsB: ["된장찌개", "불고기", "계란국"],
            updatedAt: Date(),
            updatedBy: nil
        )
    )
}

#Preview(as: .systemMedium) {
    SSAFYHubBTypeWidget()
} timeline: {
    SSAFYHubTimelineEntry(
        date: Date(),
        menu: MealMenu(
            id: UUID().uuidString,
            date: Date(),
            campus: Campus.daejeon,
            itemsA: ["김치찌개", "제육볶음", "미역국"],
            itemsB: ["된장찌개", "불고기", "계란국"],
            updatedAt: Date(),
            updatedBy: nil
        )
    )
}
