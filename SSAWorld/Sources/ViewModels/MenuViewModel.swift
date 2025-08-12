import Foundation
import SwiftUI

@MainActor
class MenuViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var selectedCampus: Campus = .seoul
    @Published var currentMenu: Menu?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        loadTodayMenu()
    }
    
    // MARK: - Date Navigation
    func goToNextDay() {
        let calendar = Calendar.current
        if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
            currentDate = nextDate
            loadMenuForCurrentDate()
        }
    }
    
    func goToPreviousDay() {
        let calendar = Calendar.current
        if let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) {
            currentDate = previousDate
            loadMenuForCurrentDate()
        }
    }
    
    func goToToday() {
        currentDate = Date()
        loadMenuForCurrentDate()
    }
    
    // MARK: - Menu Loading
    func loadTodayMenu() {
        currentDate = Date()
        loadMenuForCurrentDate()
    }
    
    func loadMenuForCurrentDate() {
        Task {
            await loadMenu(for: currentDate)
        }
    }
    
    private func loadMenu(for date: Date) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentMenu = try await supabaseService.fetchMenu(for: date, campus: selectedCampus)
        } catch {
            errorMessage = "메뉴를 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Campus Management
    func updateCampus(_ campus: Campus) {
        selectedCampus = campus
        loadMenuForCurrentDate()
    }
    
    // MARK: - Menu Management
    func saveMenu(itemsA: [String], itemsB: [String]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let menuInput = MenuInput(
                date: currentDate,
                campus: selectedCampus,
                itemsA: itemsA,
                itemsB: itemsB
            )
            
            if let existingMenu = currentMenu {
                currentMenu = try await supabaseService.updateMenu(existingMenu, with: menuInput)
            } else {
                currentMenu = try await supabaseService.saveMenu(menuInput)
            }
        } catch {
            errorMessage = "메뉴 저장에 실패했습니다: \(error.localizedDescription)"
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
