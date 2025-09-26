import Foundation

// MARK: - 에러 복구 전략 프로토콜
public protocol ErrorRecoveryStrategy {
    func canRecover(from error: AppError) -> Bool
    func attemptRecovery() async throws
    var maxRetryAttempts: Int { get }
    var retryDelay: TimeInterval { get }
}

// MARK: - 네트워크 에러 복구 전략
public class NetworkErrorRecoveryStrategy: ErrorRecoveryStrategy {
    public let maxRetryAttempts: Int = 3
    public let retryDelay: TimeInterval = 2.0
    
    private var currentAttempt: Int = 0
    
    public func canRecover(from error: AppError) -> Bool {
        guard case .network(let networkError) = error else { return false }
        return networkError.isRecoverable && currentAttempt < maxRetryAttempts
    }
    
    public func attemptRecovery() async throws {
        currentAttempt += 1
        
        // 네트워크 상태 확인
        try await checkNetworkConnectivity()
        
        // 재시도 전 대기
        try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(currentAttempt) * 1_000_000_000))
    }
    
    private func checkNetworkConnectivity() async throws {
        // 네트워크 연결 상태 확인 로직
        // 실제 구현에서는 NetworkMonitor를 사용
        print("🌐 네트워크 연결 상태 확인 중...")
    }
    
    public func reset() {
        currentAttempt = 0
    }
}

// MARK: - AI 서비스 에러 복구 전략
public class AIErrorRecoveryStrategy: ErrorRecoveryStrategy {
    public let maxRetryAttempts: Int = 2
    public let retryDelay: TimeInterval = 5.0
    
    private var currentAttempt: Int = 0
    
    public func canRecover(from error: AppError) -> Bool {
        guard case .ai(let aiError) = error else { return false }
        return aiError.isRecoverable && currentAttempt < maxRetryAttempts
    }
    
    public func attemptRecovery() async throws {
        currentAttempt += 1
        
        // AI 서비스 상태 확인
        try await checkAIServiceStatus()
        
        // 재시도 전 대기 (AI 서비스는 더 긴 대기 시간 필요)
        try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(currentAttempt) * 1_000_000_000))
    }
    
    private func checkAIServiceStatus() async throws {
        // AI 서비스 상태 확인 로직
        print("🤖 AI 서비스 상태 확인 중...")
    }
    
    public func reset() {
        currentAttempt = 0
    }
}

// MARK: - 인증 에러 복구 전략
public class AuthErrorRecoveryStrategy: ErrorRecoveryStrategy {
    public let maxRetryAttempts: Int = 1
    public let retryDelay: TimeInterval = 1.0
    
    private var currentAttempt: Int = 0
    
    public func canRecover(from error: AppError) -> Bool {
        guard case .authentication(let authError) = error else { return false }
        return authError.isRecoverable && currentAttempt < maxRetryAttempts
    }
    
    public func attemptRecovery() async throws {
        currentAttempt += 1
        
        // 세션 갱신 시도
        try await refreshSession()
    }
    
    private func refreshSession() async throws {
        // 세션 갱신 로직
        print("🔐 세션 갱신 시도 중...")
    }
    
    public func reset() {
        currentAttempt = 0
    }
}

// MARK: - 데이터 에러 복구 전략
public class DataErrorRecoveryStrategy: ErrorRecoveryStrategy {
    public let maxRetryAttempts: Int = 2
    public let retryDelay: TimeInterval = 1.0
    
    private var currentAttempt: Int = 0
    
    public func canRecover(from error: AppError) -> Bool {
        guard case .data(let dataError) = error else { return false }
        return dataError.isRecoverable && currentAttempt < maxRetryAttempts
    }
    
    public func attemptRecovery() async throws {
        currentAttempt += 1
        
        // 데이터 동기화 시도
        try await syncData()
        
        // 재시도 전 대기
        try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
    }
    
    private func syncData() async throws {
        // 데이터 동기화 로직
        print("💾 데이터 동기화 시도 중...")
    }
    
    public func reset() {
        currentAttempt = 0
    }
}
