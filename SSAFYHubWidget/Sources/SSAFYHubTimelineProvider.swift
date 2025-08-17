import WidgetKit
import SwiftUI
import SharedModels

struct SSAFYHubTimelineEntry: TimelineEntry {
    let date: Date
    let menu: MealMenu?
}

struct SSAFYHubTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SSAFYHubTimelineEntry {
        SSAFYHubTimelineEntry(
            date: Date(),
            menu: MealMenu(
                id: UUID().uuidString,
                date: Date(),
                campus: .daejeon,
                itemsA: ["김치찌개", "제육볶음", "미역국"],
                itemsB: ["된장찌개", "불고기", "계란국"],
                updatedAt: Date(),
                updatedBy: nil
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SSAFYHubTimelineEntry) -> ()) {
        let entry = SSAFYHubTimelineEntry(
            date: Date(),
            menu: MealMenu(
                id: UUID().uuidString,
                date: Date(),
                campus: .daejeon,
                itemsA: ["김치찌개", "제육볶음", "미역국"],
                itemsB: ["된장찌개", "불고기", "계란국"],
                updatedAt: Date(),
                updatedBy: nil
            )
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SSAFYHubTimelineEntry>) -> ()) {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // 오늘 날짜만 사용 (시간은 제거)
        let today = calendar.startOfDay(for: currentDate)
        
        // 현재 메뉴 데이터 가져오기
        let currentMenu = getCurrentMenu()
        
        // 위젯은 오늘 날짜로만 업데이트 (다른 날짜로 변경해도 반영하지 않음)
        let updateTimes: [Date] = [
            today, // 오늘 시작
            calendar.date(byAdding: .hour, value: 6, to: today)!, // 오전 6시
            calendar.date(byAdding: .hour, value: 12, to: today)!, // 오후 12시
            calendar.date(byAdding: .hour, value: 18, to: today)!, // 오후 6시
            calendar.date(byAdding: .day, value: 1, to: today)! // 다음날 (새로운 타임라인 시작)
        ]
        
        // 모든 엔트리는 오늘 날짜의 메뉴를 사용
        let allEntries = updateTimes.map { date in
            SSAFYHubTimelineEntry(
                date: date,
                menu: currentMenu
            )
        }
        
        let timeline = Timeline(entries: allEntries, policy: .atEnd)
        
        print("📱 위젯 타임라인 생성: \(allEntries.count)개 엔트리 (오늘 날짜만)")
        print("   - 오늘 날짜: \(today)")
        if let menu = currentMenu {
            print("   - 메뉴 데이터: \(menu.date), A타입 \(menu.itemsA.count)개, B타입 \(menu.itemsB.count)개")
            print("   - 메뉴 ID: \(menu.id)")
            print("   - 캠퍼스: \(menu.campus)")
        } else {
            print("   - 메뉴 데이터: ❌ 없음")
            print("   - App Group 데이터 공유 확인 필요")
            print("   - 메인 앱에서 메뉴 로드 필요")
        }
        
        completion(timeline)
    }
    
    private func getCurrentMenu() -> MealMenu? {
        // UserDefaults를 통해 메인 앱과 데이터 공유
        let userDefaults = UserDefaults(suiteName: "group.com.coby.ssafyhub")
        
        print("🔍 위젯: App Group UserDefaults 접근 시도")
        print("   - Suite Name: group.com.coby.ssafyhub")
        print("   - UserDefaults 객체: \(userDefaults?.description ?? "nil")")
        print("   - Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("   - App Group 접근 시도 시간: \(Date())")
        
        // UserDefaults가 nil인지 확인
        guard let userDefaults = userDefaults else {
            print("❌ 위젯: UserDefaults 객체가 nil입니다")
            print("   - App Group 권한 문제일 수 있습니다")
            return nil
        }
        
        // 저장된 모든 키와 값 확인
        let allKeys = userDefaults.dictionaryRepresentation()
        print("   - 저장된 모든 키: \(Array(allKeys.keys))")
        
        for (key, value) in allKeys {
            print("   - 키 '\(key)': \(value)")
        }
        
        guard let menuData = userDefaults.data(forKey: "currentMenu") else {
            print("❌ 위젯: 메뉴 데이터를 찾을 수 없음")
            print("   - UserDefaults 키: currentMenu")
            print("   - UserDefaults 객체: \(userDefaults.description)")
            
            // 다른 키들도 확인
            for key in allKeys.keys {
                if let value = allKeys[key] {
                    print("   - 키 '\(key)': \(value)")
                }
            }
            
            return nil
        }
        
        print("✅ 위젯: 메뉴 데이터 발견 - 크기: \(menuData.count) bytes")
        
        do {
            let menu = try JSONDecoder().decode(MealMenu.self, from: menuData)
            print("✅ 위젯: 메뉴 데이터 디코딩 성공 - \(menu.date)")
            print("   - A타입: \(menu.itemsA)")
            print("   - B타입: \(menu.itemsB)")
            return menu
        } catch {
            print("❌ 위젯: 메뉴 데이터 디코딩 실패 - \(error)")
            
            // 원본 데이터를 문자열로 출력하여 디버깅
            if let jsonString = String(data: menuData, encoding: .utf8) {
                print("   - 원본 JSON 데이터: \(jsonString)")
            }
            
            return nil
        }
    }
}


