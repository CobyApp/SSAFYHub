import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        public var currentUser: AppUser?
        public var isSigningOut = false
        public var errorMessage: String?
        public var showingSignOutAlert = false
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case signOutTapped
        case confirmSignOut
        case cancelSignOut
        case exitGuestMode
        case signOutCompleted
        case signOutFailed(String)
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
                
            case .exitGuestMode:
                // 게스트 모드 종료 - 사용자 정보만 제거
                state.currentUser = nil
                return .none
                
            case .signOutCompleted:
                state.currentUser = nil
                return .none
                
            case let .signOutFailed(error):
                state.errorMessage = error
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
