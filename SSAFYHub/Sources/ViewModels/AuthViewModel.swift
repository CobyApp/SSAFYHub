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
    
    var currentUser: User? {
        if case .authenticated(let user) = authState {
            return user
        }
        return nil
    }
    
    init() {
        checkAuthState()
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
            authState = .authenticated(user)
        } catch {
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
    
    private func fetchUserData(userId: String) async throws -> User {
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
