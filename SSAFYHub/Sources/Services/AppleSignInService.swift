import Foundation
import AuthenticationServices
import Supabase

@MainActor
class AppleSignInService: NSObject, ObservableObject, Sendable {
    static let shared = AppleSignInService()
    
    private let supabaseService = SupabaseService.shared
    private var isSignInInProgress = false  // 로그인 진행 상태 추가
    
    private override init() {
        super.init()
    }
    
    func signInWithApple() async throws -> User {
        // 중복 실행 방지
        guard !isSignInInProgress else {
            print("⚠️ AppleSignInService: Apple 로그인이 이미 진행 중입니다")
            throw NSError(domain: "AppleSignInError", code: -12, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인이 이미 진행 중입니다"])
        }
        
        isSignInInProgress = true  // 로그인 진행 상태 설정
        
        defer {
            isSignInInProgress = false  // 함수 종료 시 상태 초기화
        }
        
        print("🍎 Apple 로그인 시작 - continuation 생성")
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = [.fullName, .email]
                
                let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                let delegate = AppleSignInDelegate(continuation: continuation, supabaseService: self.supabaseService)
                
                // delegate를 강하게 참조하여 continuation 누수 방지
                authorizationController.delegate = delegate
                authorizationController.presentationContextProvider = delegate
                
                // delegate를 authorizationController에 연결하여 생명주기 관리
                objc_setAssociatedObject(authorizationController, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                print("🍎 Apple 로그인 팝업 표시 시작")
                authorizationController.performRequests()
                
                // 타임아웃 시간을 15초로 증가 (Apple 로그인은 시간이 걸릴 수 있음)
                DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                    if !delegate.hasResumed {
                        print("⏰ Apple 로그인 타임아웃 (15초)")
                        delegate.handleTimeout()
                    }
                }
            }
        }
    }
}

@MainActor
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<User, Error>
    private let supabaseService: SupabaseService
    private(set) var hasResumed = false
    
    init(continuation: CheckedContinuation<User, Error>, supabaseService: SupabaseService) {
        self.continuation = continuation
        self.supabaseService = supabaseService
        print("🍎 AppleSignInDelegate 초기화됨")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("🍎 presentationAnchor 요청됨")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("⚠️ presentation anchor를 찾을 수 없음")
            // presentation anchor를 찾을 수 없는 경우 continuation resume
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
        
        // 즉시 hasResumed을 true로 설정하여 중복 처리 방지
        hasResumed = true
        
        Task {
            do {
                let user = try await supabaseService.authenticateWithApple(identityToken: identityToken)
                print("🍎 Supabase 인증 성공: \(user.email)")
                
                // continuation resume (이미 hasResumed이 true이므로 중복 방지됨)
                print("✅ continuation resume 성공")
                continuation.resume(returning: user)
                
            } catch {
                print("❌ Supabase 인증 실패: \(error)")
                // 에러 발생 시에도 continuation resume
                continuation.resume(throwing: error)
            }
        }
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
    
    // deinit에서도 continuation이 resume되지 않았으면 에러로 처리
    deinit {
        print("🍎 AppleSignInDelegate deinit")
        guard !hasResumed else { return }
        print("⚠️ deinit에서 continuation resume")
        hasResumed = true
        continuation.resume(throwing: NSError(domain: "AppleSignInError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Apple Sign In was cancelled or failed"]))
    }
}
