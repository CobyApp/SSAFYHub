import Foundation
import AuthenticationServices
import Supabase

@MainActor
class AppleSignInService: NSObject, ObservableObject, Sendable {
    static let shared = AppleSignInService()
    
    private let supabaseService = SupabaseService.shared
    
    private override init() {
        super.init()
    }
    
    func signInWithApple() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = [.fullName, .email]
                
                let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                let delegate = AppleSignInDelegate(continuation: continuation, supabaseService: self.supabaseService)
                authorizationController.delegate = delegate
                authorizationController.presentationContextProvider = delegate
                authorizationController.performRequests()
            }
        }
    }
}

@MainActor
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<User, Error>
    private let supabaseService: SupabaseService
    
    init(continuation: CheckedContinuation<User, Error>, supabaseService: SupabaseService) {
        self.continuation = continuation
        self.supabaseService = supabaseService
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"]))
            return
        }
        
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Identity token not found"]))
            return
        }
        
        Task {
            do {
                let user = try await supabaseService.authenticateWithApple(identityToken: identityToken)
                continuation.resume(returning: user)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}
