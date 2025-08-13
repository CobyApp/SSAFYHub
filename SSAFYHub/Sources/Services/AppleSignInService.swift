import Foundation
import AuthenticationServices

@MainActor
class AppleSignInService: NSObject, ObservableObject, Sendable {
    static let shared = AppleSignInService()
    
    private override init() {
        super.init()
    }
    
    func signInWithApple() async throws -> String {
        print("🍎 Apple 로그인 시작")
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = [.fullName, .email]
                
                let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                let delegate = AppleSignInDelegate(continuation: continuation)
                
                authorizationController.delegate = delegate
                authorizationController.presentationContextProvider = delegate
                
                print("🍎 Apple 로그인 팝업 표시")
                authorizationController.performRequests()
                
                // 타임아웃 설정 (30초)
                DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                    if !delegate.hasResumed {
                        print("⏰ Apple 로그인 타임아웃")
                        delegate.handleTimeout()
                    }
                }
            }
        }
    }
}

@MainActor
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<String, Error>
    private(set) var hasResumed = false
    
    init(continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
        print("🍎 AppleSignInDelegate 초기화됨")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("⚠️ presentation anchor를 찾을 수 없음")
            if !hasResumed {
                hasResumed = true
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -3, userInfo: [NSLocalizedDescriptionKey: "No window found"]))
            }
            return UIWindow()
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard !hasResumed else { return }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            hasResumed = true
            continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential"]))
            return
        }
        
        hasResumed = true
        continuation.resume(returning: identityToken)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard !hasResumed else { return }
        hasResumed = true
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -5, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인이 취소되었습니다."]))
            default:
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -6, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인에 실패했습니다."]))
            }
        } else {
            continuation.resume(throwing: error)
        }
    }
    
    func handleTimeout() {
        guard !hasResumed else { return }
        hasResumed = true
        continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -8, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 시간이 초과되었습니다."]))
    }
    
    deinit {
        guard !hasResumed else { return }
        hasResumed = true
        continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Apple Sign In was cancelled or failed"]))
    }
}
