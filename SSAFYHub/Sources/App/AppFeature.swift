import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var auth = AuthFeature.State()
        public var menu = MenuFeature.State()
        public var menuEditor = MenuEditorFeature.State()
        public var settings = SettingsFeature.State()
        public var currentTab: Tab = .main
        public var isInitialized = false
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case auth(AuthFeature.Action)
        case menu(MenuFeature.Action)
        case menuEditor(MenuEditorFeature.Action)
        case settings(SettingsFeature.Action)
        case tabChanged(Tab)
        case onAppear
        case initializationComplete
    }
    
    public enum Tab: Equatable {
        case main
        case settings
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        
        Scope(state: \.menu, action: \.menu) {
            MenuFeature()
        }
        
        Scope(state: \.menuEditor, action: \.menuEditor) {
            MenuEditorFeature()
        }
        
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.auth(.onAppear))
                
            case let .tabChanged(tab):
                state.currentTab = tab
                return .none
                
            case .auth(.onAppear):
                return .none
                
            case .auth(.signInAsGuest):
                return .none
                
            case .auth(.exitGuestMode):
                // 게스트 모드 종료 시 메뉴 캠퍼스 초기화
                state.menu.campus = .daejeon
                // SettingsFeature에서도 사용자 정보 제거
                state.settings.currentUser = nil
                return .none
                
            case .auth(.signOut):
                return .none
                
            case .auth(.userAuthenticated(let user)):
                // 사용자 인증 시 메뉴 캠퍼스 설정
                state.menu.campus = user.campus
                // SettingsFeature에도 사용자 정보 전달
                state.settings.currentUser = user
                return .none
                
            case .auth(.userSignedOut):
                // 로그아웃 시 메뉴 캠퍼스 초기화
                state.menu.campus = .daejeon
                // SettingsFeature에서도 사용자 정보 제거
                state.settings.currentUser = nil
                return .none
                
            case .auth(.setLoading(_)):
                return .none
                
            case .auth(.setError(_)):
                return .none
                
            case .auth(.clearError):
                return .none
                
            case .initializationComplete:
                state.isInitialized = true
                return .none
                
            case .menu, .menuEditor, .settings:
                return .none
            }
        }
    }
}
