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
        print("📱 위젯 스냅샷 요청")
        
        // 스냅샷에서는 캐시된 데이터가 있으면 사용, 없으면 기본 데이터 사용
        let menu: MealMenu? = getCurrentMenu() ?? createDefaultMenu(for: Date())
        
        let entry = SSAFYHubTimelineEntry(
            date: Date(),
            menu: menu
        )
        
        print("📱 위젯 스냅샷 생성 완료")
        if let menu = menu {
            print("   - 메뉴 데이터: \(menu.date), A타입 \(menu.itemsA.count)개, B타입 \(menu.itemsB.count)개")
        }
        
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SSAFYHubTimelineEntry>) -> ()) {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // 오늘 날짜만 사용 (시간은 제거)
        let today = calendar.startOfDay(for: currentDate)
        
        print("📱 위젯 타임라인 시작 - 오늘 날짜: \(today)")
        
        // 위젯은 오늘 날짜로만 업데이트 (다른 날짜로 변경해도 반영하지 않음)
        let updateTimes: [Date] = [
            today, // 오늘 시작
            calendar.date(byAdding: .hour, value: 6, to: today)!, // 오전 6시
            calendar.date(byAdding: .hour, value: 12, to: today)!, // 오후 12시
            calendar.date(byAdding: .hour, value: 18, to: today)!, // 오후 6시
            calendar.date(byAdding: .day, value: 1, to: today)! // 다음날 (새로운 타임라인 시작)
        ]
        
        // 캐시된 데이터 확인 (로깅용)
        let cachedMenu = getCurrentMenu()
        if let menu = cachedMenu {
            print("📱 위젯: 캐시된 메뉴 데이터 발견")
            print("   - 캐시된 메뉴: \(menu.date), A타입 \(menu.itemsA.count)개, B타입 \(menu.itemsB.count)개")
            print("   - 메뉴 ID: \(menu.id)")
        } else {
            print("📱 위젯: 캐시된 데이터 없음")
        }
        
        // 항상 네트워크 요청을 시도하여 최신 데이터 가져오기
        print("🌐 위젯: 네트워크 요청 시작 (최신 데이터 확인)")
        
        Task {
            do {
                print("🌐 위젯: 네트워크 요청 시작")
                let menu = try await fetchMenuFromAPI(date: today)
                
                print("✅ 위젯: 네트워크 요청 성공")
                
                // 모든 엔트리는 오늘 날짜의 메뉴를 사용
                let allEntries = updateTimes.map { date in
                    SSAFYHubTimelineEntry(
                        date: date,
                        menu: menu
                    )
                }
                
                let timeline = Timeline(entries: allEntries, policy: .atEnd)
                
                print("📱 위젯 타임라인 생성: \(allEntries.count)개 엔트리")
                if let menu = menu {
                    print("   - 메뉴 데이터: \(menu.date), A타입 \(menu.itemsA.count)개, B타입 \(menu.itemsB.count)개")
                    print("   - 메뉴 ID: \(menu.id)")
                    print("   - 캠퍼스: \(menu.campus)")
                } else {
                    print("   - 메뉴 데이터: ❌ 없음 (해당 날짜에 메뉴가 없음)")
                }
                
                await MainActor.run {
                    completion(timeline)
                }
                
            } catch {
                print("❌ 위젯: 네트워크 요청 실패 - \(error)")
                
                // 네트워크 실패 시 캐시된 데이터 사용, 없으면 기본 데이터 사용
                let fallbackMenu: MealMenu? = cachedMenu ?? createDefaultMenu(for: today)
                
                let allEntries = updateTimes.map { date in
                    SSAFYHubTimelineEntry(
                        date: date,
                        menu: fallbackMenu
                    )
                }
                
                let timeline = Timeline(entries: allEntries, policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()))
                
                print("📱 위젯 타임라인 생성 (폴백 데이터 사용): \(allEntries.count)개 엔트리")
                if let menu = fallbackMenu {
                    if cachedMenu != nil {
                        print("   - 캐시된 메뉴 데이터 사용: \(menu.date), A타입 \(menu.itemsA.count)개, B타입 \(menu.itemsB.count)개")
                    } else {
                        print("   - 기본 메뉴 데이터 사용: \(menu.date), A타입 \(menu.itemsA.count)개, B타입 \(menu.itemsB.count)개")
                    }
                } else {
                    print("   - 폴백 메뉴 데이터: ❌ 없음")
                }
                
                await MainActor.run {
                    completion(timeline)
                }
            }
        }
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
    
    // MARK: - 위젯에서 직접 API 호출
    private func fetchMenuFromAPI(date: Date) async throws -> MealMenu? {
        // App Group에서 Supabase 설정 가져오기
        guard let userDefaults = UserDefaults(suiteName: "group.com.coby.ssafyhub") else {
            print("❌ 위젯: App Group UserDefaults 접근 실패")
            throw WidgetError.missingConfiguration
        }
        
        let supabaseURL = userDefaults.string(forKey: "supabase_url") ?? ""
        let supabaseAnonKey = userDefaults.string(forKey: "supabase_anon_key") ?? ""
        
        guard !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty else {
            print("❌ 위젯: Supabase 설정이 없습니다")
            throw WidgetError.missingConfiguration
        }
        
        // 날짜 포맷팅
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let dateString = dateFormatter.string(from: date)
        
        // API URL 구성
        let urlString = "\(supabaseURL)/rest/v1/menus?date=eq.\(dateString)&campus_id=eq.daejeon&select=id,date,campus_id,items_a,items_b,updated_at,updated_by"
        
        guard let url = URL(string: urlString) else {
            print("❌ 위젯: 잘못된 URL - \(urlString)")
            throw WidgetError.invalidURL
        }
        
        print("🔗 위젯: API 요청 URL - \(urlString)")
        
        // 네트워크 요청 생성
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("prefer", forHTTPHeaderField: "return=representation")
        
        // 타임아웃 설정 (위젯은 제한된 시간)
        request.timeoutInterval = 10.0
        
        do {
            print("📡 위젯: 네트워크 요청 실행")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 위젯: HTTP 응답이 아닙니다")
                throw WidgetError.invalidResponse
            }
            
            print("📥 위젯: HTTP 응답 수신 - 상태 코드: \(httpResponse.statusCode)")
            print("📦 위젯: 응답 데이터 크기: \(data.count) bytes")
            
            if httpResponse.statusCode == 200 {
                // JSON 파싱
                let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                
                guard let menuData = jsonArray?.first else {
                    print("⚠️ 위젯: 해당 날짜의 메뉴가 없습니다")
                    return nil
                }
                
                // MealMenu 객체로 변환
                let menu = try parseMenuFromJSON(menuData)
                print("✅ 위젯: 메뉴 데이터 파싱 성공 - ID: \(menu.id)")
                print("   - A타입: \(menu.itemsA.count)개")
                print("   - B타입: \(menu.itemsB.count)개")
                
                return menu
                
            } else {
                print("❌ 위젯: API 요청 실패 - 상태 코드: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("   - 에러 응답: \(errorString)")
                }
                throw WidgetError.apiRequestFailed(httpResponse.statusCode)
            }
            
        } catch {
            print("❌ 위젯: 네트워크 요청 실패 - \(error.localizedDescription)")
            throw WidgetError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - JSON 파싱 헬퍼
    private func parseMenuFromJSON(_ json: [String: Any]) throws -> MealMenu {
        guard let id = json["id"] as? String,
              let dateString = json["date"] as? String,
              let campusString = json["campus_id"] as? String,
              let itemsA = json["items_a"] as? [String],
              let itemsB = json["items_b"] as? [String],
              let updatedAtString = json["updated_at"] as? String else {
            throw WidgetError.parsingFailed
        }
        
        // 날짜 파싱
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        guard let date = dateFormatter.date(from: dateString) else {
            throw WidgetError.dateParsingFailed
        }
        
        // 캠퍼스 파싱
        guard let campus = Campus(rawValue: campusString) else {
            throw WidgetError.campusParsingFailed
        }
        
        // 업데이트 시간 파싱
        let iso8601Formatter = ISO8601DateFormatter()
        let updatedAt = iso8601Formatter.date(from: updatedAtString) ?? Date()
        
        let updatedBy = json["updated_by"] as? String
        
        return MealMenu(
            id: id,
            date: date,
            campus: campus,
            itemsA: itemsA,
            itemsB: itemsB,
            updatedAt: updatedAt,
            updatedBy: updatedBy
        )
    }
    
    // 위젯 첫 설치 시 사용할 기본 메뉴 생성
    private func createDefaultMenu(for date: Date) -> MealMenu {
        print("🍽️ 위젯: 기본 메뉴 데이터 생성")
        
        return MealMenu(
            id: "default-\(date.timeIntervalSince1970)",
            date: date,
            campus: .daejeon,
            itemsA: [
                "김치찌개",
                "제육볶음", 
                "미역국",
                "깍두기",
                "공기밥"
            ],
            itemsB: [
                "된장찌개",
                "불고기",
                "계란국",
                "배추김치",
                "공기밥"
            ],
            updatedAt: Date(),
            updatedBy: nil
        )
    }
    
}

// MARK: - 위젯 에러 타입
enum WidgetError: Error, LocalizedError {
    case missingConfiguration
    case invalidURL
    case invalidResponse
    case apiRequestFailed(Int)
    case networkError(String)
    case parsingFailed
    case dateParsingFailed
    case campusParsingFailed
    
    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "위젯 설정이 누락되었습니다"
        case .invalidURL:
            return "잘못된 API URL입니다"
        case .invalidResponse:
            return "유효하지 않은 응답입니다"
        case .apiRequestFailed(let code):
            return "API 요청 실패 (코드: \(code))"
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .parsingFailed:
            return "데이터 파싱에 실패했습니다"
        case .dateParsingFailed:
            return "날짜 파싱에 실패했습니다"
        case .campusParsingFailed:
            return "캠퍼스 파싱에 실패했습니다"
        }
    }
}


