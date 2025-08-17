import Foundation
import SwiftUI
import SharedModels

@MainActor
class MenuViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var selectedCampus: Campus = .daejeon  // 기본값을 대전으로 변경
    @Published var currentMenu: MealMenu?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let supabaseService = SupabaseService.shared
    
    init() {
        // init 시점에는 메뉴를 로드하지 않음
        // 사용자가 캠퍼스를 설정한 후 loadMenuForCurrentDate() 호출
        
        // 현재 날짜를 시간 제거하고 설정
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // 주말이면 가장 가까운 월요일로 설정
        if weekday == 1 { // 일요일
            // 다음 주 월요일
            if let nextMonday = calendar.date(byAdding: .day, value: 1, to: today) {
                currentDate = calendar.startOfDay(for: nextMonday)
            } else {
                currentDate = calendar.startOfDay(for: today)
            }
        } else if weekday == 7 { // 토요일
            // 다음 주 월요일
            if let nextMonday = calendar.date(byAdding: .day, value: 2, to: today) {
                currentDate = calendar.startOfDay(for: nextMonday)
            } else {
                currentDate = calendar.startOfDay(for: today)
            }
        } else {
            // 평일이면 오늘 날짜
            currentDate = calendar.startOfDay(for: today)
        }
        
        print("📅 MenuViewModel 초기화 - 설정된 날짜: \(currentDate)")
    }
    
    // MARK: - Initialization
    func initializeWithCampus(_ campus: Campus) {
        selectedCampus = campus
        loadMenuForCurrentDate()
    }
    
    // MARK: - Date Navigation
    func goToNextDay() {
        let calendar = Calendar.current
        var nextDate = currentDate
        
        // 다음 평일 찾기 (토요일, 일요일 건너뛰기)
        repeat {
            if let tempDate = calendar.date(byAdding: .day, value: 1, to: nextDate) {
                nextDate = tempDate
                let weekday = calendar.component(.weekday, from: nextDate)
                // weekday: 1=일요일, 2=월요일, ..., 7=토요일
                if weekday != 1 && weekday != 7 { // 일요일과 토요일이 아닌 경우
                    break
                }
            } else {
                return
            }
        } while true
        
        // 시간을 제거하고 날짜만 설정
        currentDate = calendar.startOfDay(for: nextDate)
        print("📅 다음 평일로 이동: \(currentDate)")
        loadMenuForCurrentDate()
    }
    
    func goToPreviousDay() {
        let calendar = Calendar.current
        var previousDate = currentDate
        
        // 이전 평일 찾기 (토요일, 일요일 건너뛰기)
        repeat {
            if let tempDate = calendar.date(byAdding: .day, value: -1, to: previousDate) {
                previousDate = tempDate
                let weekday = calendar.component(.weekday, from: previousDate)
                // weekday: 1=일요일, 2=월요일, ..., 7=토요일
                if weekday != 1 && weekday != 7 { // 일요일과 토요일이 아닌 경우
                    break
                }
            } else {
                return
            }
        } while true
        
        // 시간을 제거하고 날짜만 설정
        currentDate = calendar.startOfDay(for: previousDate)
        print("📅 이전 평일로 이동: \(currentDate)")
        loadMenuForCurrentDate()
    }
    
    func loadTodayMenu() {
        let calendar = Calendar.current
        currentDate = calendar.startOfDay(for: Date())
        print("📅 오늘 날짜로 설정: \(currentDate)")
        loadMenuForCurrentDate()
    }
    
    func loadMenuForCurrentDate() {
        print("📋 MenuViewModel: 메뉴 로딩 시작")
        
        // 날짜에서 시간 제거 (날짜만 사용)
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: currentDate)
        print("📅 날짜: \(dateOnly) (시간 제거됨)")
        print("🏫 캠퍼스: \(selectedCampus.displayName)")
        
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let fetchedMenu = try await supabaseService.fetchMenu(date: dateOnly, campus: selectedCampus)
                
                await MainActor.run {
                    if let menu = fetchedMenu {
                        self.currentMenu = menu
                        print("✅ 메뉴 로딩 성공: A타입 \(menu.itemsA.count)개, B타입 \(menu.itemsB.count)개")
                        
                        // 위젯에 메뉴 데이터 공유
                        WidgetDataService.shared.shareMenuToWidget(menu)
                    } else {
                        print("📭 해당 날짜에 메뉴 없음")
                        
                        // 위젯 데이터 초기화
                        WidgetDataService.shared.clearWidgetData()
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ 메뉴 로딩 실패: \(error)")
                    
                    // 구체적인 에러 타입 확인
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .typeMismatch(let type, let context):
                            print("🔍 디코딩 에러 - 타입 불일치: \(type), 경로: \(context.codingPath)")
                            self.errorMessage = "메뉴 데이터 형식이 올바르지 않습니다."
                        case .keyNotFound(let key, let context):
                            print("🔍 디코딩 에러 - 키 누락: \(key), 경로: \(context.codingPath)")
                            self.errorMessage = "메뉴 데이터에 필요한 정보가 누락되었습니다."
                        case .valueNotFound(let type, let context):
                            print("🔍 디코딩 에러 - 값 누락: \(type), 경로: \(context.codingPath)")
                            self.errorMessage = "메뉴 데이터에 값이 누락되었습니다."
                        case .dataCorrupted(let context):
                            print("🔍 디코딩 에러 - 데이터 손상: \(context)")
                            self.errorMessage = "메뉴 데이터가 손상되었습니다."
                        @unknown default:
                            print("🔍 디코딩 에러 - 알 수 없는 에러")
                            self.errorMessage = "메뉴 데이터를 처리할 수 없습니다."
                        }
                    } else {
                        self.errorMessage = "메뉴를 불러오는 데 실패했습니다: \(error.localizedDescription)"
                    }
                    
                    self.currentMenu = nil
                }
            }
            isLoading = false
        }
    }
    
    // MARK: - Campus Management
    func updateCampus(newCampus: Campus) {
        selectedCampus = newCampus
        loadMenuForCurrentDate()
    }
    
    // MARK: - Menu Saving
    func saveMenu(menuInput: MealMenuInput, updatedBy: String?) async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabaseService.saveMenu(menuInput: menuInput, updatedBy: updatedBy)
            loadMenuForCurrentDate() // Reload menu after saving
            
            // 메뉴 저장 후 위젯 데이터도 업데이트
            if let currentMenu = self.currentMenu {
                WidgetDataService.shared.shareMenuToWidget(currentMenu)
            }
        } catch {
            errorMessage = "메뉴 저장에 실패했습니다: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // MARK: - Weekly Menu Saving
    func saveWeeklyMenu(weeklyInput: WeeklyMealMenuInput, updatedBy: String?) async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabaseService.saveWeeklyMenu(weeklyInput: weeklyInput, updatedBy: updatedBy)
            loadMenuForCurrentDate() // Reload current date menu after saving
        } catch {
            errorMessage = "주간 메뉴 저장에 실패했습니다: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // MARK: - Date Validation
    var canGoToNextDay: Bool {
        let calendar = Calendar.current
        let today = Date()
        let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        return nextDate <= today
    }
    
    var canGoToPreviousDay: Bool {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        return previousDate >= weekAgo
    }
    
    // MARK: - Date Formatting
    var dateDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: currentDate)
    }
    
    var isToday: Bool {
        Calendar.current.isDate(currentDate, inSameDayAs: Date())
    }
}
