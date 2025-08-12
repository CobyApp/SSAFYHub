import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        checkAuthState()
    }
    
    // MARK: - Authentication
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await supabaseService.signInWithApple()
            authState = .authenticated(user)
        } catch {
            errorMessage = "로그인에 실패했습니다: \(error.localizedDescription)"
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
    
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.deleteAccount()
            authState = .unauthenticated
        } catch {
            errorMessage = "계정 삭제에 실패했습니다: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - User Management
    func updateUserCampus(_ campus: Campus) async {
        guard case .authenticated(let user) = authState else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.updateUserCampus(campus)
            // 사용자 정보 업데이트
            let updatedUser = User(
                id: user.id,
                email: user.email,
                campus: campus,
                createdAt: user.createdAt,
                updatedAt: Date()
            )
            authState = .authenticated(updatedUser)
        } catch {
            errorMessage = "캠퍼스 변경에 실패했습니다: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Auth State Management
    private func checkAuthState() {
        // TODO: Supabase 세션 상태 확인
        // 임시로 로그인되지 않은 상태로 설정
        authState = .unauthenticated
    }
    
    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }
    
    var currentUser: User? {
        if case .authenticated(let user) = authState {
            return user
        }
        return nil
    }
}
