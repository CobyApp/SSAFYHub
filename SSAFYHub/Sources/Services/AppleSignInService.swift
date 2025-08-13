import Foundation
import AuthenticationServices
import Supabase

@MainActor
class AppleSignInService: NSObject, ObservableObject, Sendable {
    static let shared = AppleSignInService()
    
    private let supabaseService = SupabaseService.shared
    private var currentDelegate: AppleSignInDelegate?
    
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
                let delegate = AppleSignInDelegate(continuation: continuation, supabaseService: self.supabaseService)
                
                // 현재 delegate 참조 저장
                self.currentDelegate = delegate
                
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
    private let supabaseService: SupabaseService
    private(set) var hasResumed = false
    
    init(continuation: CheckedContinuation<String, Error>, supabaseService: SupabaseService) {
        self.continuation = continuation
        self.supabaseService = supabaseService
        print("🍎 AppleSignInDelegate 초기화됨")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("🍎 presentationAnchor 요청됨")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("⚠️ presentation anchor를 찾을 수 없음")
            if !hasResumed {
                hasResumed = true
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -3, userInfo: [NSLocalizedDescriptionKey: "No window found"]))
            }
            return UIWindow()
        }
        print("✅ presentation anchor 찾음")
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Apple 로그인 인증 완료됨")
        guard !hasResumed else { 
            print("⚠️ 이미 resume됨, 중복 처리 방지")
            return 
        }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("❌ 유효하지 않은 credential 타입")
            hasResumed = true
            continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"]))
            return
        }
        
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            print("❌ Identity token을 찾을 수 없음")
            hasResumed = true
            continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Identity token not found"]))
            return
        }
        
        print("🍎 Identity token 획득, Supabase 인증 시작")
        hasResumed = true
        
        // Identity token을 바로 반환 (Supabase 인증은 AuthViewModel에서 처리)
        print("✅ continuation resume 성공")
        continuation.resume(returning: identityToken)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("🍎 Apple 로그인 에러 발생: \(error)")
        guard !hasResumed else { 
            print("⚠️ 이미 resume됨, 중복 처리 방지")
            return 
        }
        hasResumed = true
        
        // 사용자가 취소하거나 팝업을 닫은 경우 적절한 에러 메시지 표시
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                print("🍎 사용자가 Apple 로그인 취소")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -5, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인이 취소되었습니다."]))
            case .failed:
                print("🍎 Apple 로그인 실패")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -6, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인에 실패했습니다."]))
            case .invalidResponse:
                print("🍎 Apple 로그인 응답이 유효하지 않음")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -7, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 응답이 유효하지 않습니다."]))
            case .notHandled:
                print("🍎 Apple 로그인이 처리되지 않음")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -8, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인이 처리되지 않았습니다."]))
            case .unknown:
                print("🍎 Apple 로그인 중 알 수 없는 오류")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -9, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 중 알 수 없는 오류가 발생했습니다."]))
            case .invalidRequest:
                print("🍎 Apple 로그인 요청이 유효하지 않음")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -12, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 요청이 유효하지 않습니다."]))
            case .invalidClient:
                print("🍎 Apple 로그인 클라이언트가 유효하지 않음")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -13, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 클라이언트가 유효하지 않습니다."]))
            case .invalidScope:
                print("🍎 Apple 로그인 스코프가 유효하지 않음")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -14, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 스코프가 유효하지 않습니다."]))
            case .invalidGrant:
                print("🍎 Apple 로그인 그랜트가 유효하지 않음")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -15, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 그랜트가 유효하지 않습니다."]))
            case .unauthorizedClient:
                print("🍎 Apple 로그인 클라이언트가 인증되지 않음")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -16, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 클라이언트가 인증되지 않았습니다."]))
            case .unsupportedGrantType:
                print("🍎 Apple 로그인 그랜트 타입이 지원되지 않음")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -17, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 그랜트 타입이 지원되지 않습니다."]))
            case .insufficientScope:
                print("🍎 Apple 로그인 스코프가 부족함")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -18, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 스코프가 부족합니다."]))
            case .serverError:
                print("🍎 Apple 로그인 서버 오류")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -19, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 서버 오류가 발생했습니다."]))
            case .temporarilyUnavailable:
                print("🍎 Apple 로그인 서비스가 일시적으로 사용 불가")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -20, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 서비스가 일시적으로 사용할 수 없습니다."]))
            @unknown default:
                print("🍎 Apple 로그인 중 알 수 없는 오류 (default)")
                continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -10, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 중 오류가 발생했습니다."]))
            }
        } else {
            print("🍎 일반적인 Apple 로그인 오류")
            continuation.resume(throwing: error)
        }
    }
    
    // MARK: - Timeout Handling
    func handleTimeout() {
        guard !hasResumed else { return }
        hasResumed = true
        print("⏰ 타임아웃으로 continuation resume")
        continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -11, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 시간이 초과되었습니다. 다시 시도해주세요."]))
    }
    
    // deinit에서 continuation이 resume되지 않았으면 에러로 처리
    deinit {
        print("🍎 AppleSignInDelegate deinit")
        guard !hasResumed else { return }
        print("⚠️ deinit에서 continuation resume")
        hasResumed = true
        continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Apple Sign In was cancelled or failed"]))
    }
}
