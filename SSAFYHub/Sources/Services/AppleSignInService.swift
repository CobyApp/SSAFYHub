import Foundation
import AuthenticationServices
import KeychainAccess

@MainActor
class AppleSignInService: NSObject, ObservableObject, Sendable {
    static let shared = AppleSignInService()
    
    private let keychain = Keychain(service: "com.coby.ssafyhub.apple")
    
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
    
    // MARK: - Apple 사용자 정보 키체인 관리
    func saveAppleUserInfo(userID: String, email: String?, fullName: String?) {
        keychain["userID"] = userID
        keychain["email"] = email
        keychain["fullName"] = fullName
        print("🔑 Apple 사용자 정보 키체인 저장 완료")
    }
    
    func getAppleUserInfo() -> (userID: String?, email: String?, fullName: String?) {
        let userID = keychain["userID"]
        let email = keychain["email"]
        let fullName = keychain["fullName"]
        return (userID, email, fullName)
    }
    
    func clearAppleUserInfo() {
        try? keychain.remove("userID")
        try? keychain.remove("email")
        try? keychain.remove("fullName")
        print("🗑️ Apple 사용자 정보 키체인 정리 완료")
    }
}
