import ComposableArchitecture
import Foundation
import SharedModels
import IdentifiedCollections
import UIKit

@Reducer
public struct MenuEditorFeature {
    @ObservableState
    public struct State: Equatable {
        public var selectedWeekStart: Date = Date()
        public var weeklyMenuItems: [IdentifiedArrayOf<MenuItem>] = Array(repeating: IdentifiedArray(), count: 5)
        public var isSaving = false
        public var errorMessage: String?
        public var campus: Campus = .daejeon
        public var isAnalyzingImage = false
        public var showImagePicker = false
        public var imagePickerSourceType: ImagePickerSourceType = .camera
        public var shouldDismiss = false
        
        public enum ImagePickerSourceType: Equatable {
            case camera
            case photoLibrary
        }
        
        public init() {
            // 각 요일별로 기본 메뉴 아이템 초기화
            for dayIndex in 0..<5 {
                weeklyMenuItems[dayIndex] = IdentifiedArray(uniqueElements: [
                    MenuItem(text: "", mealType: .a),
                    MenuItem(text: "", mealType: .b)
                ])
            }
        }
    }
    
    public enum Action: Equatable {
        case onAppear
        case weekStartChanged(Date)
        case itemChanged(dayIndex: Int, itemId: MenuItem.ID, text: String)
        case saveWeeklyMenu
        case saveCompleted
        case saveFailed(String)
        case setSaving(Bool)
        case setError(String?)
        case clearError
        case showImagePicker(State.ImagePickerSourceType)
        case hideImagePicker
        case analyzeImageData(Data)
        case imageAnalysisCompleted([MealMenu])
        case imageAnalysisFailed(String)
        case setAnalyzingImage(Bool)
    }
    
    @Dependency(\.supabaseService) var supabaseService
    @Dependency(\.chatGPTService) var chatGPTService
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case let .weekStartChanged(date):
                state.selectedWeekStart = date
                return .none
                
            case let .itemChanged(dayIndex, itemId, text):
                if dayIndex >= 0 && dayIndex < state.weeklyMenuItems.count,
                   let itemIndex = state.weeklyMenuItems[dayIndex].indices.first(where: { state.weeklyMenuItems[dayIndex][$0].id == itemId }) {
                    state.weeklyMenuItems[dayIndex][itemIndex].text = text
                }
                return .none
                
            case .saveWeeklyMenu:
                state.isSaving = true
                state.errorMessage = nil
                return .run { [selectedWeekStart = state.selectedWeekStart, campus = state.campus, weeklyMenuItems = state.weeklyMenuItems] send in
                    do {
                        let calendar = Calendar.current
                        let monday = selectedWeekStart
                        
                        for dayOffset in 0..<5 {
                            let date = calendar.date(byAdding: .day, value: dayOffset, to: monday) ?? Date()
                            let dayItems = weeklyMenuItems[dayOffset]
                            
                            let itemsA = dayItems.filter { $0.mealType == .a }.map { $0.text }
                            let itemsB = dayItems.filter { $0.mealType == .b }.map { $0.text }
                            
                            let hasValidItemsA = itemsA.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                            let hasValidItemsB = itemsB.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                            
                            guard hasValidItemsA || hasValidItemsB else { continue }
                            
                            let menuInput = MealMenuInput(
                                date: date,
                                campus: campus,
                                itemsA: itemsA,
                                itemsB: itemsB
                            )
                            
                            try await supabaseService.saveMenu(menuInput: menuInput, updatedBy: nil)
                        }
                        
                        await send(.saveCompleted)
                        await send(.setSaving(false))
                    } catch {
                        await send(.saveFailed(error.localizedDescription))
                        await send(.setSaving(false))
                    }
                }
                
            case .saveCompleted:
                state.shouldDismiss = true
                return .none
                
            case let .saveFailed(error):
                state.errorMessage = error
                return .none
                
            case let .setSaving(isSaving):
                state.isSaving = isSaving
                return .none
                
            case let .setError(message):
                state.errorMessage = message
                return .none
                
            case .clearError:
                state.errorMessage = nil
                return .none
                
            case let .showImagePicker(sourceType):
                state.imagePickerSourceType = sourceType
                state.showImagePicker = true
                return .none
                
            case .hideImagePicker:
                state.showImagePicker = false
                return .none
                
            case let .analyzeImageData(imageData):
                state.isAnalyzingImage = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        guard let image = UIImage(data: imageData) else {
                            await send(.imageAnalysisFailed("이미지 데이터를 읽을 수 없습니다"))
                            await send(.setAnalyzingImage(false))
                            return
                        }
                        let menus = try await chatGPTService.analyzeMenuImage(image)
                        await send(.imageAnalysisCompleted(menus))
                        await send(.setAnalyzingImage(false))
                    } catch {
                        await send(.imageAnalysisFailed(error.localizedDescription))
                        await send(.setAnalyzingImage(false))
                    }
                }
                
            case let .imageAnalysisCompleted(menus):
                // AI가 분석한 메뉴 데이터를 weeklyMenuItems에 적용
                // 주말 처리를 포함하여 올바른 날짜에 메뉴 적용
                let calendar = Calendar.current
                let monday = state.selectedWeekStart
                
                for (dayIndex, menu) in menus.enumerated() {
                    guard dayIndex < state.weeklyMenuItems.count else { break }
                    
                    // 해당 요일의 날짜 계산 (월요일부터 금요일까지)
                    let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: monday) ?? Date()
                    
                    // 주말인 경우 다음 월요일로 이동
                    let adjustedDate = adjustWeekendDate(targetDate)
                    let adjustedDayIndex = calendar.dateComponents([.day], from: monday, to: adjustedDate).day ?? dayIndex
                    
                    // 유효한 인덱스 범위 내에서만 처리
                    let finalDayIndex = max(0, min(adjustedDayIndex, state.weeklyMenuItems.count - 1))
                    
                    // A타입 메뉴 업데이트
                    if let aItem = state.weeklyMenuItems[finalDayIndex].first(where: { $0.mealType == .a }) {
                        let menuText = menu.itemsA.joined(separator: ", ")
                        if let itemIndex = state.weeklyMenuItems[finalDayIndex].firstIndex(where: { $0.id == aItem.id }) {
                            state.weeklyMenuItems[finalDayIndex][itemIndex].text = menuText
                        }
                    }
                    
                    // B타입 메뉴 업데이트
                    if let bItem = state.weeklyMenuItems[finalDayIndex].first(where: { $0.mealType == .b }) {
                        let menuText = menu.itemsB.joined(separator: ", ")
                        if let itemIndex = state.weeklyMenuItems[finalDayIndex].firstIndex(where: { $0.id == bItem.id }) {
                            state.weeklyMenuItems[finalDayIndex][itemIndex].text = menuText
                        }
                    }
                }
                state.showImagePicker = false
                return .none
                
            case let .imageAnalysisFailed(error):
                state.errorMessage = "이미지 분석 실패: \(error)"
                state.showImagePicker = false
                return .none
                
            case let .setAnalyzingImage(isAnalyzing):
                state.isAnalyzingImage = isAnalyzing
                return .none
            }
        }
    }
    
    // 주말 날짜를 다음 월요일로 조정
    private func adjustWeekendDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // 토요일(7) 또는 일요일(1)인 경우 다음 월요일로 이동
        if weekday == 1 { // 일요일
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        } else if weekday == 7 { // 토요일
            return calendar.date(byAdding: .day, value: 2, to: date) ?? date
        }
        
        return date
    }
}
