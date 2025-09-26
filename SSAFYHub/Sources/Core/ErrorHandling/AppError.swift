import Foundation

// MARK: - 중앙화된 에러 처리 시스템
public enum AppError: Error, LocalizedError, Equatable, Hashable {
    // 네트워크 관련 에러
    case network(NetworkError)
    
    // 인증 관련 에러
    case authentication(AuthError)
    
    // 데이터 관련 에러
    case data(DataError)
    
    // AI 서비스 관련 에러
    case ai(AIError)
    
    // 일반적인 에러
    case general(GeneralError)
    
    // MARK: - 사용자 친화적 에러 메시지
    public var errorDescription: String? {
        switch self {
        case .network(let networkError):
            return networkError.userFriendlyMessage
            
        case .authentication(let authError):
            return authError.userFriendlyMessage
            
        case .data(let dataError):
            return dataError.userFriendlyMessage
            
        case .ai(let aiError):
            return aiError.userFriendlyMessage
            
        case .general(let generalError):
            return generalError.userFriendlyMessage
        }
    }
    
    // MARK: - 기술적 에러 메시지 (개발자용)
    public var technicalDescription: String? {
        switch self {
        case .network(let networkError):
            return networkError.technicalMessage
            
        case .authentication(let authError):
            return authError.technicalMessage
            
        case .data(let dataError):
            return dataError.technicalMessage
            
        case .ai(let aiError):
            return aiError.technicalMessage
            
        case .general(let generalError):
            return generalError.technicalMessage
        }
    }
    
    // MARK: - 에러 복구 가능 여부
    public var isRecoverable: Bool {
        switch self {
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
    
    // MARK: - 에러 심각도
    public var severity: ErrorSeverity {
        switch self {
        case .network(let networkError):
            return networkError.severity
            
        case .authentication(let authError):
            return authError.severity
            
        case .data(let dataError):
            return dataError.severity
            
        case .ai(let aiError):
            return aiError.severity
            
        case .general(let generalError):
            return generalError.severity
        }
    }
}

// MARK: - 에러 심각도
public enum ErrorSeverity: Int, CaseIterable {
    case low = 1      // 정보성 에러
    case medium = 2   // 경고
    case high = 3     // 심각한 에러
    case critical = 4 // 치명적 에러
    
    public var displayName: String {
        switch self {
        case .low: return "정보"
        case .medium: return "경고"
        case .high: return "에러"
        case .critical: return "치명적"
        }
    }
}

// MARK: - 네트워크 에러
public enum NetworkError: Error, Equatable, Hashable {
    case noConnection
    case timeout
    case serverError(Int) // HTTP 상태 코드
    case invalidResponse
    case requestFailed(String)
    case rateLimitExceeded
    case serviceUnavailable
    
    public var userFriendlyMessage: String {
        switch self {
        case .noConnection:
            return "인터넷 연결을 확인해주세요."
        case .timeout:
            return "요청 시간이 초과되었습니다. 다시 시도해주세요."
        case .serverError(let code):
            switch code {
            case 500...599:
                return "서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요."
            case 400...499:
                return "요청을 처리할 수 없습니다. 앱을 다시 시작해주세요."
            default:
                return "서버 오류가 발생했습니다. (오류 코드: \(code))"
            }
        case .invalidResponse:
            return "서버 응답을 처리할 수 없습니다."
        case .requestFailed(let reason):
            return "요청이 실패했습니다: \(reason)"
        case .rateLimitExceeded:
            return "요청 횟수가 초과되었습니다. 잠시 후 다시 시도해주세요."
        case .serviceUnavailable:
            return "서비스가 일시적으로 사용할 수 없습니다."
        }
    }
    
    public var technicalMessage: String {
        switch self {
        case .noConnection:
            return "Network connection unavailable"
        case .timeout:
            return "Request timeout"
        case .serverError(let code):
            return "Server error with status code: \(code)"
        case .invalidResponse:
            return "Invalid server response format"
        case .requestFailed(let reason):
            return "Request failed: \(reason)"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        case .serviceUnavailable:
            return "Service temporarily unavailable"
        }
    }
    
    public var isRecoverable: Bool {
        switch self {
        case .noConnection, .timeout, .rateLimitExceeded, .serviceUnavailable:
            return true
        case .serverError(let code):
            return code >= 500 // 서버 에러는 재시도 가능
        case .invalidResponse, .requestFailed:
            return false
        }
    }
    
    public var severity: ErrorSeverity {
        switch self {
        case .noConnection, .timeout:
            return .medium
        case .serverError(let code):
            return code >= 500 ? .high : .medium
        case .invalidResponse, .requestFailed:
            return .high
        case .rateLimitExceeded:
            return .medium
        case .serviceUnavailable:
            return .high
        }
    }
}

// MARK: - 인증 에러
public enum AuthError: Error, Equatable, Hashable {
    case userNotFound
    case invalidCredentials
    case sessionExpired
    case accountLocked
    case permissionDenied
    case appleSignInFailed(String)
    case guestModeNotAvailable
    
    public var userFriendlyMessage: String {
        switch self {
        case .userNotFound:
            return "사용자 정보를 찾을 수 없습니다."
        case .invalidCredentials:
            return "로그인 정보가 올바르지 않습니다."
        case .sessionExpired:
            return "로그인이 만료되었습니다. 다시 로그인해주세요."
        case .accountLocked:
            return "계정이 잠겼습니다. 관리자에게 문의하세요."
        case .permissionDenied:
            return "권한이 부족합니다."
        case .appleSignInFailed(let reason):
            return "Apple 로그인에 실패했습니다: \(reason)"
        case .guestModeNotAvailable:
            return "게스트 모드를 사용할 수 없습니다."
        }
    }
    
    public var technicalMessage: String {
        switch self {
        case .userNotFound:
            return "User not found in database"
        case .invalidCredentials:
            return "Invalid authentication credentials"
        case .sessionExpired:
            return "User session has expired"
        case .accountLocked:
            return "User account is locked"
        case .permissionDenied:
            return "Insufficient permissions"
        case .appleSignInFailed(let reason):
            return "Apple Sign-In failed: \(reason)"
        case .guestModeNotAvailable:
            return "Guest mode is not available"
        }
    }
    
    public var isRecoverable: Bool {
        switch self {
        case .sessionExpired, .appleSignInFailed:
            return true
        case .userNotFound, .invalidCredentials, .accountLocked, .permissionDenied, .guestModeNotAvailable:
            return false
        }
    }
    
    public var severity: ErrorSeverity {
        switch self {
        case .sessionExpired, .appleSignInFailed:
            return .medium
        case .userNotFound, .invalidCredentials:
            return .high
        case .accountLocked, .permissionDenied, .guestModeNotAvailable:
            return .high
        }
    }
}

// MARK: - 데이터 에러
public enum DataError: Error, Equatable, Hashable {
    case parsingFailed
    case dataCorrupted
    case dataNotFound
    case invalidDataFormat
    case databaseError(String)
    case syncFailed
    case validationFailed(String)
    
    public var userFriendlyMessage: String {
        switch self {
        case .parsingFailed:
            return "데이터를 처리할 수 없습니다."
        case .dataCorrupted:
            return "데이터가 손상되었습니다. 앱을 다시 시작해주세요."
        case .dataNotFound:
            return "요청한 데이터를 찾을 수 없습니다."
        case .invalidDataFormat:
            return "데이터 형식이 올바르지 않습니다."
        case .databaseError(let reason):
            return "데이터베이스 오류가 발생했습니다: \(reason)"
        case .syncFailed:
            return "데이터 동기화에 실패했습니다."
        case .validationFailed(let reason):
            return "데이터 검증에 실패했습니다: \(reason)"
        }
    }
    
    public var technicalMessage: String {
        switch self {
        case .parsingFailed:
            return "Failed to parse data"
        case .dataCorrupted:
            return "Data corruption detected"
        case .dataNotFound:
            return "Requested data not found"
        case .invalidDataFormat:
            return "Invalid data format"
        case .databaseError(let reason):
            return "Database error: \(reason)"
        case .syncFailed:
            return "Data synchronization failed"
        case .validationFailed(let reason):
            return "Data validation failed: \(reason)"
        }
    }
    
    public var isRecoverable: Bool {
        switch self {
        case .parsingFailed, .syncFailed:
            return true
        case .dataCorrupted, .dataNotFound, .invalidDataFormat, .databaseError, .validationFailed:
            return false
        }
    }
    
    public var severity: ErrorSeverity {
        switch self {
        case .parsingFailed, .syncFailed:
            return .medium
        case .dataCorrupted, .databaseError:
            return .high
        case .dataNotFound, .invalidDataFormat, .validationFailed:
            return .medium
        }
    }
}

// MARK: - AI 서비스 에러
public enum AIError: Error, Equatable, Hashable {
    case imageConversionFailed
    case apiRequestFailed
    case noContentReceived
    case parsingFailed
    case quotaExceeded
    case modelUnavailable
    case invalidImageFormat
    
    public var userFriendlyMessage: String {
        switch self {
        case .imageConversionFailed:
            return "이미지를 처리할 수 없습니다. 다른 이미지를 시도해주세요."
        case .apiRequestFailed:
            return "AI 서비스 요청에 실패했습니다. 다시 시도해주세요."
        case .noContentReceived:
            return "AI에서 응답을 받지 못했습니다."
        case .parsingFailed:
            return "AI 응답을 처리할 수 없습니다."
        case .quotaExceeded:
            return "AI 서비스 사용량이 초과되었습니다. 잠시 후 다시 시도해주세요."
        case .modelUnavailable:
            return "AI 서비스가 일시적으로 사용할 수 없습니다."
        case .invalidImageFormat:
            return "지원하지 않는 이미지 형식입니다."
        }
    }
    
    public var technicalMessage: String {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to required format"
        case .apiRequestFailed:
            return "AI API request failed"
        case .noContentReceived:
            return "No content received from AI service"
        case .parsingFailed:
            return "Failed to parse AI response"
        case .quotaExceeded:
            return "AI service quota exceeded"
        case .modelUnavailable:
            return "AI model temporarily unavailable"
        case .invalidImageFormat:
            return "Unsupported image format"
        }
    }
    
    public var isRecoverable: Bool {
        switch self {
        case .apiRequestFailed, .quotaExceeded, .modelUnavailable:
            return true
        case .imageConversionFailed, .noContentReceived, .parsingFailed, .invalidImageFormat:
            return false
        }
    }
    
    public var severity: ErrorSeverity {
        switch self {
        case .imageConversionFailed, .invalidImageFormat:
            return .medium
        case .apiRequestFailed, .noContentReceived, .parsingFailed:
            return .high
        case .quotaExceeded, .modelUnavailable:
            return .medium
        }
    }
}

// MARK: - 일반 에러
public enum GeneralError: Error, Equatable, Hashable {
    case unknown
    case notImplemented
    case invalidOperation
    case resourceUnavailable
    case configurationError(String)
    
    public var userFriendlyMessage: String {
        switch self {
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        case .notImplemented:
            return "해당 기능은 아직 구현되지 않았습니다."
        case .invalidOperation:
            return "올바르지 않은 작업입니다."
        case .resourceUnavailable:
            return "필요한 리소스를 사용할 수 없습니다."
        case .configurationError(let reason):
            return "설정 오류가 발생했습니다: \(reason)"
        }
    }
    
    public var technicalMessage: String {
        switch self {
        case .unknown:
            return "Unknown error occurred"
        case .notImplemented:
            return "Feature not implemented"
        case .invalidOperation:
            return "Invalid operation attempted"
        case .resourceUnavailable:
            return "Required resource unavailable"
        case .configurationError(let reason):
            return "Configuration error: \(reason)"
        }
    }
    
    public var isRecoverable: Bool {
        switch self {
        case .unknown, .notImplemented, .invalidOperation:
            return false
        case .resourceUnavailable:
            return true
        case .configurationError:
            return false
        }
    }
    
    public var severity: ErrorSeverity {
        switch self {
        case .unknown, .configurationError:
            return .high
        case .notImplemented:
            return .medium
        case .invalidOperation:
            return .medium
        case .resourceUnavailable:
            return .medium
        }
    }
}
