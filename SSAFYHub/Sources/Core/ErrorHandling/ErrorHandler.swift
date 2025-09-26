import Foundation
import Dependencies

// MARK: - 에러 핸들링 결과
public struct ErrorHandlingResult {
    public let shouldRetry: Bool
    public let userMessage: String
    public let technicalMessage: String
    public let severity: ErrorSeverity
    public let recoveryAttempted: Bool
    
    public init(shouldRetry: Bool, userMessage: String, technicalMessage: String, severity: ErrorSeverity, recoveryAttempted: Bool = false) {
        self.shouldRetry = shouldRetry
        self.userMessage = userMessage
        self.technicalMessage = technicalMessage
        self.severity = severity
        self.recoveryAttempted = recoveryAttempted
    }
}

// MARK: - 에러 핸들러 프로토콜
public protocol ErrorHandlerProtocol {
    func handle(_ error: Error) async -> ErrorHandlingResult
    func handle(_ error: AppError) async -> ErrorHandlingResult
    func canRetry(_ error: AppError) -> Bool
    func attemptRecovery(for error: AppError) async throws
}

// MARK: - 중앙화된 에러 핸들러
public class ErrorHandler: ErrorHandlerProtocol {
    public static let shared = ErrorHandler()
    
    private var recoveryStrategies: [AppError: ErrorRecoveryStrategy] = [:]
    
    private init() {
        setupRecoveryStrategies()
    }
    
    private func setupRecoveryStrategies() {
        recoveryStrategies = [
            .network(.noConnection): NetworkErrorRecoveryStrategy(),
            .network(.timeout): NetworkErrorRecoveryStrategy(),
            .network(.rateLimitExceeded): NetworkErrorRecoveryStrategy(),
            .network(.serviceUnavailable): NetworkErrorRecoveryStrategy(),
            .ai(.apiRequestFailed): AIErrorRecoveryStrategy(),
            .ai(.quotaExceeded): AIErrorRecoveryStrategy(),
            .ai(.modelUnavailable): AIErrorRecoveryStrategy(),
            .authentication(.sessionExpired): AuthErrorRecoveryStrategy(),
            .authentication(.appleSignInFailed("")): AuthErrorRecoveryStrategy(),
            .data(.syncFailed): DataErrorRecoveryStrategy(),
            .data(.parsingFailed): DataErrorRecoveryStrategy()
        ]
    }
    
    // MARK: - 일반 Error 처리
    public func handle(_ error: Error) async -> ErrorHandlingResult {
        // Error를 AppError로 변환
        let appError = convertToAppError(error)
        return await handle(appError)
    }
    
    // MARK: - AppError 처리
    public func handle(_ error: AppError) async -> ErrorHandlingResult {
        print("🚨 ErrorHandler: 에러 처리 시작")
        print("   - 에러 타입: \(type(of: error))")
        print("   - 사용자 메시지: \(error.errorDescription ?? "알 수 없는 오류")")
        print("   - 기술적 메시지: \(error.technicalDescription ?? "No technical message")")
        print("   - 심각도: \(error.severity.displayName)")
        print("   - 복구 가능: \(error.isRecoverable)")
        
        // 에러 로깅
        await logError(error)
        
        // 복구 시도
        var recoveryAttempted = false
        if canRetry(error) {
            do {
                try await attemptRecovery(for: error)
                recoveryAttempted = true
                print("✅ ErrorHandler: 복구 시도 성공")
            } catch {
                print("❌ ErrorHandler: 복구 시도 실패 - \(error)")
            }
        }
        
        // 결과 반환
        let result = ErrorHandlingResult(
            shouldRetry: canRetry(error) && recoveryAttempted,
            userMessage: error.errorDescription ?? "알 수 없는 오류가 발생했습니다.",
            technicalMessage: error.technicalDescription ?? "No technical message available",
            severity: error.severity,
            recoveryAttempted: recoveryAttempted
        )
        
        print("📋 ErrorHandler: 처리 결과")
        print("   - 재시도 가능: \(result.shouldRetry)")
        print("   - 복구 시도됨: \(result.recoveryAttempted)")
        
        return result
    }
    
    // MARK: - 재시도 가능 여부 확인
    public func canRetry(_ error: AppError) -> Bool {
        guard error.isRecoverable else { return false }
        
        // 특정 에러 타입에 대한 재시도 가능 여부 확인
        switch error {
        case .network(let networkError):
            return networkError.isRecoverable
        case .authentication(let authError):
            return authError.isRecoverable
        case .data(let dataError):
            return dataError.isRecoverable
        case .ai(let aiError):
            return aiError.isRecoverable
        case .general(let generalError):
            return generalError.isRecoverable
        }
    }
    
    // MARK: - 복구 시도
    public func attemptRecovery(for error: AppError) async throws {
        print("🔧 ErrorHandler: 복구 시도 시작 - \(error)")
        
        // 에러 타입에 따른 복구 전략 선택
        let strategy = getRecoveryStrategy(for: error)
        
        guard let strategy = strategy, strategy.canRecover(from: error) else {
            print("❌ ErrorHandler: 복구 전략이 없거나 복구 불가능")
            throw AppError.general(.resourceUnavailable)
        }
        
        try await strategy.attemptRecovery()
        print("✅ ErrorHandler: 복구 시도 완료")
    }
    
    // MARK: - 복구 전략 선택
    private func getRecoveryStrategy(for error: AppError) -> ErrorRecoveryStrategy? {
        switch error {
        case .network:
            return NetworkErrorRecoveryStrategy()
        case .authentication:
            return AuthErrorRecoveryStrategy()
        case .data:
            return DataErrorRecoveryStrategy()
        case .ai:
            return AIErrorRecoveryStrategy()
        case .general:
            return nil // 일반 에러는 복구 전략 없음
        }
    }
    
    // MARK: - Error를 AppError로 변환
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // 기존 에러들을 AppError로 매핑
        if let urlError = error as? URLError {
            return mapURLError(urlError)
        }
        
        if error is DecodingError {
            return AppError.data(.parsingFailed)
        }
        
        if error is EncodingError {
            return AppError.data(.parsingFailed)
        }
        
        // 알 수 없는 에러는 일반 에러로 처리
        return AppError.general(.unknown)
    }
    
    // MARK: - URLError를 AppError로 매핑
    private func mapURLError(_ urlError: URLError) -> AppError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return AppError.network(.noConnection)
        case .timedOut:
            return AppError.network(.timeout)
        case .cannotConnectToHost, .cannotFindHost:
            return AppError.network(.serviceUnavailable)
        case .badServerResponse:
            return AppError.network(.invalidResponse)
        default:
            return AppError.network(.requestFailed(urlError.localizedDescription))
        }
    }
    
    // MARK: - 에러 로깅
    private func logError(_ error: AppError) async {
        let logMessage = """
        Error occurred:
        - Type: \(type(of: error))
        - User Message: \(error.errorDescription ?? "N/A")
        - Technical Message: \(error.technicalDescription ?? "N/A")
        - Severity: \(error.severity.displayName)
        - Recoverable: \(error.isRecoverable)
        """
        
        let additionalData: [String: Any] = [
            "error_type": String(describing: type(of: error)),
            "severity": error.severity.rawValue,
            "recoverable": error.isRecoverable,
            "user_message": error.errorDescription ?? "N/A",
            "technical_message": error.technicalDescription ?? "N/A"
        ]
        
        // 에러 타입에 따른 카테고리 결정
        let category: LogCategory
        switch error {
        case .network:
            category = .network
        case .authentication:
            category = .auth
        case .data:
            category = .data
        case .ai:
            category = .ai
        case .general:
            category = .general
        }
        
        // 로그 레벨 결정
        let logLevel: LogLevel
        switch error.severity {
        case .low:
            logLevel = .info
        case .medium:
            logLevel = .warning
        case .high:
            logLevel = .error
        case .critical:
            logLevel = .critical
        }
        
        let _ = LogContext(category: category, additionalData: additionalData)
        // Logger 의존성 주입을 통해 로깅
        // await logger.log(logLevel, logMessage, context)
        
        // 임시로 print 사용 (나중에 Logger 의존성 주입으로 변경)
        print("\(logLevel.emoji) [\(category.rawValue)] \(logMessage)")
    }
}

// MARK: - Dependencies 통합
extension DependencyValues {
    var errorHandler: ErrorHandlerProtocol {
        get { self[ErrorHandlerKey.self] }
        set { self[ErrorHandlerKey.self] = newValue }
    }
}

private enum ErrorHandlerKey: DependencyKey {
    static let liveValue: ErrorHandlerProtocol = ErrorHandler.shared
}

// MARK: - 편의 메서드
public extension ErrorHandler {
    /// 에러를 처리하고 결과를 반환하는 편의 메서드
    static func handle(_ error: Error) async -> ErrorHandlingResult {
        return await shared.handle(error)
    }
    
    /// AppError를 처리하고 결과를 반환하는 편의 메서드
    static func handle(_ error: AppError) async -> ErrorHandlingResult {
        return await shared.handle(error)
    }
    
    /// 에러가 복구 가능한지 확인하는 편의 메서드
    static func canRetry(_ error: AppError) -> Bool {
        return shared.canRetry(error)
    }
}
