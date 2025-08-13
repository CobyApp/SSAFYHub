import WidgetKit
import SwiftUI
import SharedModels

struct SSAFYHubTimelineEntry: TimelineEntry {
    let date: Date
    let menu: Menu?
}

struct SSAFYHubTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SSAFYHubTimelineEntry {
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

    func getSnapshot(in context: Context, completion: @escaping (SSAFYHubTimelineEntry) -> ()) {
        let entry = SSAFYHubTimelineEntry(
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
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SSAFYHubTimelineEntry>) -> ()) {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // 오늘 날짜의 시작과 끝
        let startOfDay = calendar.startOfDay(for: currentDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // 위젯 업데이트 시간 (매일 자정, 점심시간, 저녁시간)
        let updateTimes: [Date] = [
            startOfDay, // 자정
            calendar.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate)!, // 점심
            calendar.date(bySettingHour: 18, minute: 0, second: 0, of: currentDate)!, // 저녁
            endOfDay // 다음날 자정
        ].filter { $0 > currentDate }
        
        // 현재 메뉴 데이터 가져오기 (실제로는 UserDefaults나 App Group을 통해 공유)
        let currentMenu = getCurrentMenu()
        
        let entries = updateTimes.map { date in
            SSAFYHubTimelineEntry(
                date: date,
                menu: currentMenu
            )
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func getCurrentMenu() -> Menu? {
        // UserDefaults를 통해 메인 앱과 데이터 공유
        let userDefaults = UserDefaults(suiteName: "group.com.coby")
        
        guard let menuData = userDefaults?.data(forKey: "currentMenu"),
              let menu = try? JSONDecoder().decode(Menu.self, from: menuData) else {
            return nil
        }
        
        return menu
    }
}


