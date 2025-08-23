import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        public var currentUser: AppUser?
        public var isSigningOut = false
        public var isDeletingAccount = false
        public var errorMessage: String?
        public var showingSignOutAlert = false
        public var showingDeleteAccountAlert = false
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case setCurrentUser(AppUser?)
        case signOutTapped
        case confirmSignOut
        case cancelSignOut
        case deleteAccountTapped
        case confirmDeleteAccount
        case cancelDeleteAccount
        case exitGuestMode
        case signOutCompleted
        case signOutFailed(String)
        case deleteAccountCompleted
        case deleteAccountFailed(String)
        case navigateToAuth
        case setLoading(Bool)
        case setError(String?)
        case clearError
    }
    
    @Dependency(\.supabaseService) var supabaseService
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    // 저장된 사용자 세션 복구 시도
                    if let user = await supabaseService.restoreUserSession() {
                        await send(.setCurrentUser(user))
                    }
                }
                
            case let .setCurrentUser(user):
                state.currentUser = user
                return .none
                
            case .signOutTapped:
                state.showingSignOutAlert = true
                return .none
                
            case .confirmSignOut:
                state.showingSignOutAlert = false
                state.isSigningOut = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        try await supabaseService.signOut()
                        await send(.signOutCompleted)
                        await send(.setLoading(false))
                    } catch {
                        await send(.signOutFailed(error.localizedDescription))
                        await send(.setLoading(false))
                    }
                }
                
            case .cancelSignOut:
                state.showingSignOutAlert = false
                return .none
                
            case .deleteAccountTapped:
                state.showingDeleteAccountAlert = true
                return .none
                
            case .confirmDeleteAccount:
                state.showingDeleteAccountAlert = false
                state.isDeletingAccount = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        try await supabaseService.deleteAccount()
                        await send(.deleteAccountCompleted)
                        await send(.setLoading(false))
                    } catch {
                        await send(.deleteAccountFailed(error.localizedDescription))
                        await send(.setLoading(false))
                    }
                }
                
            case .cancelDeleteAccount:
                state.showingDeleteAccountAlert = false
                return .none
                
            case .exitGuestMode:
                // 게스트 모드 종료 - 사용자 정보 제거 후 로그인 화면으로 이동
                state.currentUser = nil
                return .send(.navigateToAuth)
                
            case .signOutCompleted:
                state.currentUser = nil
                // 로그아웃 완료 후 로그인 화면으로 이동
                return .send(.navigateToAuth)
                
            case let .signOutFailed(error):
                state.errorMessage = error
                return .none
                
            case .deleteAccountCompleted:
                state.currentUser = nil
                state.isDeletingAccount = false
                // 회원탈퇴 완료 후 로그인 화면으로 이동
                return .send(.navigateToAuth)
                
            case let .deleteAccountFailed(error):
                state.errorMessage = error
                return .none
                
            case .navigateToAuth:
                // 로그인 화면으로 이동 - AppFeature에서 처리
                return .none
                
            case let .setLoading(isLoading):
                state.isSigningOut = isLoading
                return .none
                
            case let .setError(message):
                state.errorMessage = message
                return .none
                
            case .clearError:
                state.errorMessage = nil
                return .none
            }
        }
    }
}
