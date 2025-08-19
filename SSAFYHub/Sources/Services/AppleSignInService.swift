import Foundation
import AuthenticationServices
import KeychainAccess
import CryptoKit

@MainActor
class AppleSignInService: NSObject, ObservableObject, Sendable {
    static let shared = AppleSignInService()
    
    private let keychain = Keychain(service: "com.coby.ssafyhub.apple")
    
    // nonce 관리를 위한 프로퍼티
    private var currentNonce: String?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Nonce Management
    /// Apple Sign-In 요청을 위한 nonce를 생성합니다
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        print("🔐 AppleSignInService: nonce 생성됨 - \(nonce.prefix(10))...")
        return nonce
    }
    
    /// 현재 nonce를 가져옵니다
    func getCurrentNonce() -> String? {
        return currentNonce
    }
    
    /// nonce를 해시화합니다 (Apple 요청용)
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    /// 랜덤 nonce 문자열을 생성합니다
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    // SignInWithAppleButton의 onCompletion에서 직접 호출할 메서드
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) async throws -> (identityToken: String, nonce: String) {
        print("🍎 Apple 로그인 완료 처리 시작")
        
        // 현재 nonce가 있는지 확인
        guard let rawNonce = currentNonce else {
            print("❌ Apple 로그인: nonce가 설정되지 않았습니다")
            throw NSError(domain: "AppleSignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nonce가 설정되지 않았습니다"])
        }
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                print("❌ Apple 로그인 크레덴셜이 유효하지 않습니다")
                throw NSError(domain: "AppleSignInError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid credential"])
            }
            
            print("✅ Apple 로그인 성공 - Identity Token 획득")
            print("🔐 Identity Token prefix: \(identityToken.prefix(15))...")
            print("🔐 Raw Nonce: \(rawNonce)")
            
            // nonce를 사용한 후 정리
            let nonceToReturn = rawNonce
            currentNonce = nil
            
            return (identityToken, nonceToReturn)
            
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
