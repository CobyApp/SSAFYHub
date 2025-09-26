import Foundation
import Dependencies
import SharedModels
import UIKit

// MARK: - Mock Supabase Service
public class MockSupabaseService: ObservableObject {
    private var mockMenus: [String: MealMenu] = [:]
    private var mockUsers: [String: AppUser] = [:]
    
    public init() {}
    
    // MARK: - Mock Data Setup
    public func setupMockData() {
        setupMockMenus()
        setupMockUsers()
    }
    
    private func setupMockMenus() {
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                let menu = MealMenu(
                    id: UUID().uuidString,
                    date: date,
                    campus: .daejeon,
                    itemsA: ["백미밥", "된장국", "제육볶음", "시금치나물", "깍두기"],
                    itemsB: ["잡곡밥", "미역국", "닭볶음", "오이무침", "깍두기"],
                    updatedAt: Date(),
                    updatedBy: "mock_user@test.com"
                )
                mockMenus[dateKey(for: date)] = menu
            }
        }
    }
    
    private func setupMockUsers() {
        let mockUser = AppUser(
            id: "mock_user_id",
            email: "mock_user@test.com",
            campus: .daejeon,
            userType: .authenticated,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockUsers[mockUser.id] = mockUser
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Mock Supabase Service Protocol
public protocol MockSupabaseServiceProtocol {
    func fetchMenu(date: Date, campus: Campus, userId: String?) async throws -> MealMenu?
    func saveMenu(menuInput: MealMenuInput, updatedBy: String?) async throws
    func authenticateWithApple(identityToken: String, nonce: String) async throws -> AppUser
    func getCurrentUser() async throws -> AppUser?
    func signOut() async throws
}

extension MockSupabaseService: MockSupabaseServiceProtocol {
    public func fetchMenu(date: Date, campus: Campus, userId: String? = nil) async throws -> MealMenu? {
        let key = dateKey(for: date)
        return mockMenus[key]
    }
    
    public func saveMenu(menuInput: MealMenuInput, updatedBy: String?) async throws {
        let key = dateKey(for: menuInput.date)
        let menu = MealMenu(
            id: UUID().uuidString,
            date: menuInput.date,
            campus: menuInput.campus,
            itemsA: menuInput.itemsA,
            itemsB: menuInput.itemsB,
            updatedAt: Date(),
            updatedBy: updatedBy
        )
        mockMenus[key] = menu
    }
    
    public func authenticateWithApple(identityToken: String, nonce: String) async throws -> AppUser {
        let mockUser = AppUser(
            id: UUID().uuidString,
            email: "mock_user@test.com",
            campus: .daejeon,
            userType: .authenticated,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockUsers[mockUser.id] = mockUser
        return mockUser
    }
    
    public func getCurrentUser() async throws -> AppUser? {
        return mockUsers.values.first
    }
    
    public func signOut() async throws {
        mockUsers.removeAll()
    }
}

// MARK: - Mock ChatGPT Service
public class MockChatGPTService: ObservableObject {
    public init() {}
    
    public func analyzeMenuImage(_ image: UIImage) async throws -> [MealMenu] {
        // Mock AI 응답 반환
        let calendar = Calendar.current
        let today = Date()
        
        var mockMenus: [MealMenu] = []
        
        for i in 0..<5 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                let menu = MealMenu(
                    id: UUID().uuidString,
                    date: date,
                    campus: .daejeon,
                    itemsA: ["백미밥", "된장국", "제육볶음", "시금치나물", "깍두기"],
                    itemsB: ["잡곡밥", "미역국", "닭볶음", "오이무침", "깍두기"],
                    updatedAt: Date(),
                    updatedBy: "AI_Mock"
                )
                mockMenus.append(menu)
            }
        }
        
        return mockMenus
    }
}

// MARK: - Mock Error Handler
public class MockErrorHandler: ErrorHandlerProtocol {
    public init() {}
    
    public func handle(_ error: Error) async -> ErrorHandlingResult {
        return ErrorHandlingResult(
            shouldRetry: false,
            userMessage: "Mock error message",
            technicalMessage: error.localizedDescription,
            severity: .medium
        )
    }
    
    public func handle(_ error: AppError) async -> ErrorHandlingResult {
        return ErrorHandlingResult(
            shouldRetry: false,
            userMessage: "Mock error message",
            technicalMessage: error.technicalDescription ?? "Unknown error",
            severity: error.severity
        )
    }
    
    public func canRetry(_ error: AppError) -> Bool {
        return false
    }
    
    public func attemptRecovery(for error: AppError) async throws {
        // Mock recovery - nothing to do
    }
}

// MARK: - Mock Logger
public class MockLogger: LoggerProtocol {
    public init() {}
    
    public func log(_ level: LogLevel, _ message: String, _ context: LogContext) {
        print("Mock Logger [\(level.rawValue)]: \(message)")
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
}

// MARK: - Mock Cache Manager
public class MockCacheManager: CacheManagerProtocol {
    private var cache: [String: Data] = [:]
    
    public init() {}
    
    public func store<T: Codable>(_ object: T, forKey key: String, policy: CachePolicy) async {
        if let data = try? JSONEncoder().encode(object) {
            cache[key] = data
        }
    }
    
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async -> T? {
        guard let data = cache[key] else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    public func remove(forKey key: String) async {
        cache.removeValue(forKey: key)
    }
    
    public func clear() async {
        cache.removeAll()
    }
    
    public func removeExpired() async {
        // Mock implementation - no expiration logic
    }
    
    public func getCacheInfo() async -> CacheInfo {
        return CacheInfo(
            memoryEntryCount: cache.count,
            diskEntryCount: 0,
            memorySize: cache.values.reduce(0) { $0 + $1.count },
            diskSize: 0,
            hitRate: 0.8 // Mock hit rate
        )
    }
}

// MARK: - Mock Network Manager
public class MockNetworkManager {
    private var mockResponses: [String: Data] = [:]
    
    public init() {}
    
    public func setupMockResponse<T: Codable>(_ response: T, for endpoint: APIEndpoint) {
        let key = CacheManager.key(for: endpoint)
        if let data = try? JSONEncoder().encode(response) {
            mockResponses[key] = data
        }
    }
    
    public func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type, useCache: Bool = true) async throws -> T {
        let key = CacheManager.key(for: endpoint)
        
        guard let data = mockResponses[key] else {
            throw AppError.network(.requestFailed("Mock response not found"))
        }
        
        return try JSONDecoder().decode(responseType, from: data)
    }
    
    public func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        let key = CacheManager.key(for: endpoint)
        
        guard let data = mockResponses[key] else {
            throw AppError.network(.requestFailed("Mock response not found"))
        }
        
        return data
    }
}

// MARK: - Test Dependencies
public extension DependencyValues {
    var mockSupabaseService: MockSupabaseServiceProtocol {
        get { self[MockSupabaseServiceKey.self] }
        set { self[MockSupabaseServiceKey.self] = newValue }
    }
    
    var mockChatGPTService: MockChatGPTService {
        get { self[MockChatGPTServiceKey.self] }
        set { self[MockChatGPTServiceKey.self] = newValue }
    }
    
    var mockErrorHandler: ErrorHandlerProtocol {
        get { self[MockErrorHandlerKey.self] }
        set { self[MockErrorHandlerKey.self] = newValue }
    }
    
    var mockLogger: LoggerProtocol {
        get { self[MockLoggerKey.self] }
        set { self[MockLoggerKey.self] = newValue }
    }
    
    var mockCacheManager: CacheManagerProtocol {
        get { self[MockCacheManagerKey.self] }
        set { self[MockCacheManagerKey.self] = newValue }
    }
}

private enum MockSupabaseServiceKey: DependencyKey {
    static let liveValue: MockSupabaseServiceProtocol = MockSupabaseService()
}

private enum MockChatGPTServiceKey: DependencyKey {
    static let liveValue: MockChatGPTService = MockChatGPTService()
}

private enum MockErrorHandlerKey: DependencyKey {
    static let liveValue: ErrorHandlerProtocol = MockErrorHandler()
}

private enum MockLoggerKey: DependencyKey {
    static let liveValue: LoggerProtocol = MockLogger()
}

private enum MockCacheManagerKey: DependencyKey {
    static let liveValue: CacheManagerProtocol = MockCacheManager()
}

// MARK: - Test Utilities
public struct TestUtilities {
    public static func createMockMenu(date: Date, campus: Campus = .daejeon) -> MealMenu {
        return MealMenu(
            id: UUID().uuidString,
            date: date,
            campus: campus,
            itemsA: ["백미밥", "된장국", "제육볶음"],
            itemsB: ["잡곡밥", "미역국", "닭볶음"],
            updatedAt: Date(),
            updatedBy: "test_user@test.com"
        )
    }
    
    public static func createMockUser(campus: Campus = .daejeon) -> AppUser {
        return AppUser(
            id: UUID().uuidString,
            email: "test_user@test.com",
            campus: campus,
            userType: .authenticated,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    public static func createMockMenuInput(date: Date, campus: Campus = .daejeon) -> MealMenuInput {
        return MealMenuInput(
            date: date,
            campus: campus,
            itemsA: ["백미밥", "된장국", "제육볶음"],
            itemsB: ["잡곡밥", "미역국", "닭볶음"]
        )
    }
}
