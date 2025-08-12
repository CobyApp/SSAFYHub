import Foundation
import SwiftUI
import Supabase
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let supabaseService = SupabaseService.shared
    weak var coordinator: AppCoordinator?
    
    var currentUser: User? {
        if case .authenticated(let user) = authState {
            return user
        }
        return nil
    }
    
    init() {
        // init에서는 세션 체크하지 않음
        // SSAFYHubApp에서 checkInitialAuthState()를 통해 처리
    }
    
    // MARK: - Coordinator Setup
    func setCoordinator(_ coordinator: AppCoordinator) {
        self.coordinator = coordinator
        print("🔗 Coordinator 연결됨")
    }
    
    // MARK: - Auth State Check
    @MainActor
    func checkAuthState() {
        Task {
            do {
                print("🔍 AuthViewModel: 세션 상태 확인 시작")
                let session = try await supabaseService.client.auth.session
                let user = session.user
                print("🔍 AuthViewModel: 세션 발견 - 사용자 ID: \(user.id)")
                
                let userData = try await fetchUserData(userId: user.id.uuidString)
                print("🔍 AuthViewModel: 사용자 데이터 로드 완료 - \(userData.email)")
                
                authState = .authenticated(userData)
                print("✅ AuthViewModel: 인증 상태 업데이트 완료")
            } catch {
                print("❌ AuthViewModel: 세션 상태 확인 실패: \(error)")
                authState = .unauthenticated
            }
        }
    }
    
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let appleSignInService = AppleSignInService.shared
            let user = try await appleSignInService.signInWithApple()
            print("🍎 Apple 로그인 성공: \(user.email)")
            authState = .authenticated(user)
        } catch {
            print("❌ Apple 로그인 실패: \(error)")
            errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
            authState = .unauthenticated
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.signOut()
            authState = .unauthenticated
        } catch {
            errorMessage = "로그아웃에 실패했습니다: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateUserCampus(_ campus: Campus) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if case .authenticated(let user) = authState {
                try await supabaseService.updateUserCampus(userId: user.id, campus: campus)
                
                let updatedUser = User(
                    id: user.id,
                    email: user.email,
                    campus: campus,
                    userType: user.userType,  // userType 유지
                    createdAt: user.createdAt,
                    updatedAt: Date()
                )
                authState = .authenticated(updatedUser)
            }
        } catch {
            errorMessage = "캠퍼스 업데이트에 실패했습니다: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signInAsGuest(campus: Campus) async {
        print("👤 signInAsGuest 시작 - 캠퍼스: \(campus.displayName)")
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. SupabaseService를 통해 게스트 사용자 생성
            let guestUser = try await supabaseService.signInAsGuest(campus: campus)
            
            print("👤 게스트 사용자 생성됨: \(guestUser)")
            print("🔄 authState 업데이트 시작")
            
            // 2. authState 업데이트
            await MainActor.run {
                let oldState = authState
                authState = .authenticated(guestUser)
                print("✅ authState 업데이트 완료")
                print("📱 이전 상태: \(oldState)")
                print("📱 새로운 상태: \(authState)")
            }
            
            print("✅ signInAsGuest 완료")
        } catch {
            print("❌ signInAsGuest 오류: \(error)")
            errorMessage = "게스트 로그인에 실패했습니다: \(error.localizedDescription)"
            
            // 에러 발생 시 인증 상태를 unauthenticated로 설정
            await MainActor.run {
                authState = .unauthenticated
            }
        }
        
        isLoading = false
        print("🏁 signInAsGuest 종료")
    }
    
    // MARK: - Apple Sign In with Direct Navigation
    func signInWithAppleAndNavigate() async {
        // 중복 실행 방지
        guard !isLoading else {
            print("⚠️ AuthViewModel: Apple 로그인이 이미 진행 중입니다")
            return
        }
        
        print("🍎 Apple 로그인 시작")
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Apple Sign In Service를 통해 실제 Apple 로그인 수행
            let appleSignInService = AppleSignInService.shared
            let user = try await appleSignInService.signInWithApple()
            
            print("🍎 Apple 로그인 성공: \(user.email)")
            
            // 2. authState 즉시 업데이트
            await MainActor.run {
                print("🔄 Apple 로그인 authState 업데이트 시작")
                let oldState = authState
                authState = .authenticated(user)
                print("✅ Apple 로그인 authState 업데이트 완료")
                print("📱 이전 상태: \(oldState)")
                print("📱 새로운 상태: \(authState)")
                
                // 3. Coordinator를 통해 즉시 네비게이션
                if let coordinator = self.coordinator {
                    print("🎯 Coordinator를 통해 직접 네비게이션 요청")
                    coordinator.handleDirectAuthentication(user)
                } else {
                    print("⚠️ Coordinator가 연결되지 않음")
                }
            }
            
        } catch {
            print("❌ Apple 로그인 실패: \(error)")
            errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
            
            // 에러 발생 시 인증 상태를 unauthenticated로 설정
            await MainActor.run {
                authState = .unauthenticated
            }
        }
        
        isLoading = false
    }
    
    public func fetchUserData(userId: String) async throws -> User {
        let response = try await supabaseService.client
            .database
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
        
        let data = response.data
        guard let jsonResult = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "SupabaseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse user data"])
        }
        
        let email = jsonResult["email"] as? String ?? ""
        let campusId = jsonResult["campus_id"] as? String ?? "seoul"
        let campus = Campus(rawValue: campusId) ?? .seoul
        
        // user_type 필드 읽기 추가
        let userTypeString = jsonResult["user_type"] as? String ?? "authenticated"
        let userType = UserType(rawValue: userTypeString) ?? .authenticated
        
        let createdAt = ISO8601DateFormatter().date(from: jsonResult["created_at"] as? String ?? "") ?? Date()
        let updatedAt = ISO8601DateFormatter().date(from: jsonResult["updated_at"] as? String ?? "") ?? Date()
        
        return User(
            id: userId,
            email: email,
            campus: campus,
            userType: userType,  // userType 추가
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
