import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
public struct AuthFeature {
    @ObservableState
    public struct State: Equatable {
        public var currentUser: AppUser?
        public var isAuthenticated: Bool {
            currentUser != nil
        }
        public var isLoading = false
        public var errorMessage: String?
        
        public init() {
            // 초기화 시 저장된 사용자 정보 복원
            if let savedUserData = UserDefaults.standard.data(forKey: "savedUser"),
               let savedUser = try? JSONDecoder().decode(AppUser.self, from: savedUserData) {
                self.currentUser = savedUser
                print("🔐 저장된 사용자 정보 복원: \(savedUser.email)")
            }
        }
    }
    
    public enum Action: Equatable {
        case onAppear
        case signInAsGuest
        case exitGuestMode
        case signOut
        case userAuthenticated(AppUser)
        case userSignedOut
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
                    // 저장된 세션 복구 시도
                    if let user = await supabaseService.restoreUserSession() {
                        await send(.userAuthenticated(user))
                    }
                }
                
            case .signInAsGuest:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    // 게스트 사용자 생성 (대전캠퍼스)
                    let guestUser = AppUser(
                        id: UUID().uuidString,
                        email: "guest@ssafyhub.com",
                        campus: .daejeon,
                        userType: .guest,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    await send(.userAuthenticated(guestUser))
                    await send(.setLoading(false))
                }
                
            case .exitGuestMode:
                // 게스트 모드 종료 - 사용자 정보만 제거
                state.currentUser = nil
                // UserDefaults에서도 제거
                UserDefaults.standard.removeObject(forKey: "savedUser")
                return .none
                
            case .signOut:
                state.isLoading = true
                return .run { send in
                    try? await supabaseService.signOut()
                    await send(.userSignedOut)
                    await send(.setLoading(false))
                }
                
            case let .userAuthenticated(user):
                state.currentUser = user
                state.errorMessage = nil
                
                // 사용자 정보를 UserDefaults에 저장
                if let userData = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(userData, forKey: "savedUser")
                    print("🔐 사용자 정보 저장됨: \(user.email)")
                }
                
                return .none
                
            case .userSignedOut:
                state.currentUser = nil
                // UserDefaults에서도 제거
                UserDefaults.standard.removeObject(forKey: "savedUser")
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
            }
        }
    }
}
