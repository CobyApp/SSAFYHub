import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
public struct MenuFeature {
    @ObservableState
    public struct State: Equatable {
        public var currentDate: Date = Date()
        public var selectedWeekStart: Date = Date()
        public var currentMenu: MealMenu?
        public var isLoading = false
        public var errorMessage: String?
        public var campus: Campus = .daejeon
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case dateChanged(Date)
        case weekStartChanged(Date)
        case campusChanged(Campus)
        case loadMenu
        case retryFetchMenu
        case menuLoaded(MealMenu?)
        case loadMenuFailed(String)
        case setLoading(Bool)
        case setError(String?)
        case clearError
        case clearMenu
    }
    
    @Dependency(\.supabaseService) var supabaseService
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.loadMenu)
                }
                
            case let .dateChanged(date):
                state.currentDate = date
                // 날짜 변경 시 이전 메뉴 데이터 초기화
                state.currentMenu = nil
                state.errorMessage = nil
                return .run { send in
                    await send(.loadMenu)
                }
                
            case let .weekStartChanged(date):
                state.selectedWeekStart = date
                return .none
                
            case let .campusChanged(campus):
                state.campus = campus
                // 캠퍼스 변경 시 이전 메뉴 데이터 초기화
                state.currentMenu = nil
                state.errorMessage = nil
                return .run { send in
                    await send(.loadMenu)
                }
                
            case .loadMenu:
                state.isLoading = true
                state.errorMessage = nil
                return .run { [date = state.currentDate, campus = state.campus] send in
                    do {
                        let menu = try await supabaseService.fetchMenu(date: date, campus: campus)
                        await send(.menuLoaded(menu))
                    } catch {
                        await send(.loadMenuFailed(error.localizedDescription))
                    }
                    await send(.setLoading(false))
                }
                
            case .retryFetchMenu:
                state.isLoading = true
                state.errorMessage = nil
                return .run { [date = state.currentDate, campus = state.campus] send in
                    do {
                        let menu = try await supabaseService.fetchMenu(date: date, campus: campus)
                        await send(.menuLoaded(menu))
                    } catch {
                        await send(.loadMenuFailed(error.localizedDescription))
                    }
                    await send(.setLoading(false))
                }
                
            case let .menuLoaded(menu):
                state.currentMenu = menu
                return .none
                
            case let .loadMenuFailed(error):
                state.errorMessage = error
                state.currentMenu = nil
                return .none
                
            case let .setLoading(isLoading):
                state.isLoading = isLoading
                return .none
                
            case let .setError(message):
                state.errorMessage = message
                return .none
                
            case .clearError:
                state.errorMessage = nil
                return .none
                
            case .clearMenu:
                state.currentMenu = nil
                return .none
            }
        }
    }
}
