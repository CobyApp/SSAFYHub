import Foundation
import AuthenticationServices

@MainActor
class AppleSignInService: NSObject, ObservableObject, Sendable {
    static let shared = AppleSignInService()
    
    private override init() {
        super.init()
    }
    
    // SignInWithAppleButton의 onCompletion에서 직접 호출할 메서드
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) async throws -> String {
        print("🍎 Apple 로그인 완료 처리 시작")
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                print("❌ Apple 로그인 크레덴셜이 유효하지 않습니다")
                throw NSError(domain: "AppleSignInError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid credential"])
            }
            
            print("✅ Apple 로그인 성공 - Identity Token 획득")
            return identityToken
            
        case .failure(let error):
            print("❌ Apple 로그인 실패: \(error)")
            
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    print("❌ Apple 로그인 취소됨")
                    throw NSError(domain: "AppleSignInError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인이 취소되었습니다."])
                default:
                    print("❌ Apple 로그인 실패: \(authError.code)")
                    throw NSError(domain: "AppleSignInError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인에 실패했습니다."])
                }
            } else {
                print("❌ Apple 로그인 알 수 없는 에러: \(error)")
                throw error
            }
        }
    }
}
