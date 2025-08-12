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
        checkAuthState()
    }
    
    // MARK: - Coordinator Setup
    func setCoordinator(_ coordinator: AppCoordinator) {
        self.coordinator = coordinator
        print("🔗 Coordinator 연결됨")
    }
    
    func checkAuthState() {
        Task {
            do {
                let session = try await supabaseService.client.auth.session
                let user = session.user
                let userData = try await fetchUserData(userId: user.id.uuidString)
                authState = .authenticated(userData)
            } catch {
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
            // 게스트 사용자 생성 (임시 ID와 이메일)
            let guestUser = User(
                id: UUID().uuidString,
                email: "guest@ssafyhub.com",
                campus: campus,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            print("👤 게스트 사용자 생성됨: \(guestUser)")
            print("🔄 authState 업데이트 시작")
            
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
        }
        
        isLoading = false
        print("🏁 signInAsGuest 종료")
    }
    
    // MARK: - Apple Sign In with Direct Navigation
    func signInWithAppleAndNavigate() async {
        print("🍎 Apple 로그인 시작")
        isLoading = true
        errorMessage = nil
        
        do {
            // Apple 로그인은 이미 성공했으므로, Supabase 인증만 진행
            print("🍎 Supabase 인증 시작")
            
            // 임시로 테스트용 사용자 생성 (실제로는 Apple ID에서 받은 정보 사용)
            let user = User(
                id: UUID().uuidString,
                email: "apple_user@example.com",
                campus: .seoul, // 기본값, 나중에 사용자가 선택할 수 있음
                createdAt: Date(),
                updatedAt: Date()
            )
            
            print("🍎 테스트 사용자 생성: \(user.email)")
            
            // authState 즉시 업데이트
            await MainActor.run {
                print("🔄 Apple 로그인 authState 업데이트 시작")
                let oldState = authState
                authState = .authenticated(user)
                print("✅ Apple 로그인 authState 업데이트 완료")
                print("📱 이전 상태: \(oldState)")
                print("📱 새로운 상태: \(authState)")
                
                // Coordinator를 통해 즉시 네비게이션
                if let coordinator = self.coordinator {
                    print("🎯 Coordinator를 통해 직접 네비게이션 요청")
                    coordinator.handleDirectAuthentication(user)
                } else {
                    print("⚠️ Coordinator가 연결되지 않음")
                }
            }
            
        } catch {
            print("❌ Apple 로그인 실패: \(error)")
            
            await MainActor.run {
                self.errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
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
        
        let createdAt = ISO8601DateFormatter().date(from: jsonResult["created_at"] as? String ?? "") ?? Date()
        let updatedAt = ISO8601DateFormatter().date(from: jsonResult["updated_at"] as? String ?? "") ?? Date()
        
        return User(
            id: userId,
            email: email,
            campus: campus,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
