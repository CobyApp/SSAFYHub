import Foundation
import Dependencies
import os.log

// MARK: - 로그 레벨
public enum LogLevel: String, CaseIterable, Comparable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        let levels: [LogLevel] = [.debug, .info, .warning, .error, .critical]
        guard let lhsIndex = levels.firstIndex(of: lhs),
              let rhsIndex = levels.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    public var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
    
    public var emoji: String {
        switch self {
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
}

// MARK: - 로그 카테고리
public enum LogCategory: String, CaseIterable {
    case general = "General"
    case network = "Network"
    case auth = "Authentication"
    case data = "Data"
    case ai = "AI"
    case ui = "UI"
    case performance = "Performance"
    case security = "Security"
    case widget = "Widget"
    
    public var subsystem: String {
        return "com.coby.ssafyhub"
    }
}

// MARK: - 로그 컨텍스트
public struct LogContext {
    public let category: LogCategory
    public let function: String
    public let file: String
    public let line: Int
    public let timestamp: Date
    public let threadId: String
    public let userId: String?
    public let sessionId: String?
    public let additionalData: [String: Any]?
    
    public init(
        category: LogCategory,
        function: String = #function,
        file: String = #file,
        line: Int = #line,
        userId: String? = nil,
        sessionId: String? = nil,
        additionalData: [String: Any]? = nil
    ) {
        self.category = category
        self.function = function
        self.file = URL(fileURLWithPath: file).lastPathComponent
        self.line = line
        self.timestamp = Date()
        self.threadId = Thread.current.description
        self.userId = userId
        self.sessionId = sessionId
        self.additionalData = additionalData
    }
}

// MARK: - 로거 프로토콜
public protocol LoggerProtocol {
    func log(_ level: LogLevel, _ message: String, _ context: LogContext)
    func debug(_ message: String, _ context: LogContext)
    func info(_ message: String, _ context: LogContext)
    func warning(_ message: String, _ context: LogContext)
    func error(_ message: String, _ context: LogContext)
    func critical(_ message: String, _ context: LogContext)
}

// MARK: - 중앙화된 로거
public class AppLogger: LoggerProtocol {
    public static let shared = AppLogger()
    
    private let osLoggers: [LogCategory: OSLog]
    private let fileLogger: FileLogger
    private let consoleLogger: ConsoleLogger
    private let remoteLogger: RemoteLogger?
    
    private let minLogLevel: LogLevel
    private let enableConsoleLogging: Bool
    private let enableFileLogging: Bool
    private let enableRemoteLogging: Bool
    
    private init() {
        // 설정값들 (나중에 설정 시스템과 연동)
        self.minLogLevel = .debug
        self.enableConsoleLogging = true
        self.enableFileLogging = true
        self.enableRemoteLogging = false
        
        // OSLogger 초기화
        var loggers: [LogCategory: OSLog] = [:]
        for category in LogCategory.allCases {
            loggers[category] = OSLog(subsystem: category.subsystem, category: category.rawValue)
        }
        self.osLoggers = loggers
        
        // 파일 로거 초기화
        self.fileLogger = FileLogger()
        
        // 콘솔 로거 초기화
        self.consoleLogger = ConsoleLogger()
        
        // 원격 로거 초기화 (향후 구현)
        self.remoteLogger = nil
        
        print("🔧 AppLogger: 초기화 완료")
        print("   - 최소 로그 레벨: \(minLogLevel.rawValue)")
        print("   - 콘솔 로깅: \(enableConsoleLogging)")
        print("   - 파일 로깅: \(enableFileLogging)")
        print("   - 원격 로깅: \(enableRemoteLogging)")
    }
    
    // MARK: - 공개 로깅 메서드
    public func log(_ level: LogLevel, _ message: String, _ context: LogContext) {
        // 최소 로그 레벨 확인
        guard level >= minLogLevel else { return }
        
        // OS 로깅
        if let osLogger = osLoggers[context.category] {
            os_log("%{public}@", log: osLogger, type: level.osLogType, message)
        }
        
        // 콘솔 로깅
        if enableConsoleLogging {
            consoleLogger.log(level, message, context)
        }
        
        // 파일 로깅
        if enableFileLogging {
            fileLogger.log(level, message, context)
        }
        
        // 원격 로깅
        if enableRemoteLogging, let remoteLogger = remoteLogger {
            remoteLogger.log(level, message, context)
        }
    }
    
    public func debug(_ message: String, _ context: LogContext) {
        log(.debug, message, context)
    }
    
    public func info(_ message: String, _ context: LogContext) {
        log(.info, message, context)
    }
    
    public func warning(_ message: String, _ context: LogContext) {
        log(.warning, message, context)
    }
    
    public func error(_ message: String, _ context: LogContext) {
        log(.error, message, context)
    }
    
    public func critical(_ message: String, _ context: LogContext) {
        log(.critical, message, context)
    }
    
    // MARK: - 편의 메서드
    public func logNetwork(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .network, additionalData: additionalData)
        log(level, message, context)
    }
    
    public func logAuth(_ level: LogLevel, _ message: String, userId: String? = nil, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .auth, userId: userId, additionalData: additionalData)
        log(level, message, context)
    }
    
    public func logData(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .data, additionalData: additionalData)
        log(level, message, context)
    }
    
    public func logAI(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .ai, additionalData: additionalData)
        log(level, message, context)
    }
    
    public func logUI(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .ui, additionalData: additionalData)
        log(level, message, context)
    }
    
    public func logPerformance(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .performance, additionalData: additionalData)
        log(level, message, context)
    }
    
    public func logSecurity(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .security, additionalData: additionalData)
        log(level, message, context)
    }
    
    public func logWidget(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .widget, additionalData: additionalData)
        log(level, message, context)
    }
}

// MARK: - 콘솔 로거
private class ConsoleLogger {
    func log(_ level: LogLevel, _ message: String, _ context: LogContext) {
        let timestamp = DateFormatter.logFormatter.string(from: context.timestamp)
        let emoji = level.emoji
        let category = context.category.rawValue
        
        let logMessage = "\(emoji) [\(timestamp)] [\(category)] \(message)"
        
        // 추가 데이터가 있으면 포함
        if let additionalData = context.additionalData, !additionalData.isEmpty {
            let dataString = additionalData.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            print("\(logMessage) | Data: \(dataString)")
        } else {
            print(logMessage)
        }
    }
}

// MARK: - 파일 로거
private class FileLogger {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.coby.ssafyhub.filelogger", qos: .utility)
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logsDirectory = documentsPath.appendingPathComponent("Logs")
        
        // 로그 디렉토리 생성
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        
        // 로그 파일 URL (날짜별로 분리)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "app_\(dateFormatter.string(from: Date())).log"
        self.fileURL = logsDirectory.appendingPathComponent(fileName)
        
        // 오래된 로그 파일 정리 (7일 이상)
        cleanOldLogFiles(in: logsDirectory)
    }
    
    func log(_ level: LogLevel, _ message: String, _ context: LogContext) {
        queue.async { [weak self] in
            self?.writeToFile(level, message, context)
        }
    }
    
    private func writeToFile(_ level: LogLevel, _ message: String, _ context: LogContext) {
        let timestamp = DateFormatter.logFormatter.string(from: context.timestamp)
        let logEntry = "\(timestamp) [\(level.rawValue)] [\(context.category.rawValue)] \(context.file):\(context.line) - \(message)"
        
        if let data = (logEntry + "\n").data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // 파일에 추가
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                // 새 파일 생성
                try? data.write(to: fileURL)
            }
        }
    }
    
    private func cleanOldLogFiles(in directory: URL) {
        let fileManager = FileManager.default
        let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7일
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
            let now = Date()
            
            for file in files {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   now.timeIntervalSince(creationDate) > maxAge {
                    try? fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("❌ 로그 파일 정리 실패: \(error)")
        }
    }
}

// MARK: - 원격 로거 (향후 구현)
private class RemoteLogger {
    func log(_ level: LogLevel, _ message: String, _ context: LogContext) {
        // 향후 구현: Firebase Crashlytics, Sentry 등과 연동
        // 현재는 플레이스홀더
    }
}

// MARK: - DateFormatter 확장
private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

// MARK: - Dependencies 통합
extension DependencyValues {
    var logger: LoggerProtocol {
        get { self[LoggerKey.self] }
        set { self[LoggerKey.self] = newValue }
    }
}

private enum LoggerKey: DependencyKey {
    static let liveValue: LoggerProtocol = AppLogger.shared
}

// MARK: - 편의 메서드
public extension LoggerProtocol {
    /// 네트워크 관련 로그
    func logNetwork(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .network, additionalData: additionalData)
        log(level, message, context)
    }
    
    /// 인증 관련 로그
    func logAuth(_ level: LogLevel, _ message: String, userId: String? = nil, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .auth, userId: userId, additionalData: additionalData)
        log(level, message, context)
    }
    
    /// 데이터 관련 로그
    func logData(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .data, additionalData: additionalData)
        log(level, message, context)
    }
    
    /// AI 관련 로그
    func logAI(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .ai, additionalData: additionalData)
        log(level, message, context)
    }
    
    /// UI 관련 로그
    func logUI(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .ui, additionalData: additionalData)
        log(level, message, context)
    }
    
    /// 성능 관련 로그
    func logPerformance(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .performance, additionalData: additionalData)
        log(level, message, context)
    }
    
    /// 보안 관련 로그
    func logSecurity(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .security, additionalData: additionalData)
        log(level, message, context)
    }
    
    /// 위젯 관련 로그
    func logWidget(_ level: LogLevel, _ message: String, additionalData: [String: Any]? = nil) {
        let context = LogContext(category: .widget, additionalData: additionalData)
        log(level, message, context)
    }
}
