import Foundation
import Dependencies
import Network

// MARK: - 네트워크 연결 상태
public enum NetworkStatus: Equatable {
    case connected(ConnectionType)
    case disconnected
    case unknown
    
    public enum ConnectionType: Equatable {
        case wifi
        case cellular
        case ethernet
        case other
        
        public var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "셀룰러"
            case .ethernet: return "이더넷"
            case .other: return "기타"
            }
        }
    }
}

// MARK: - HTTP 메서드
public enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API 엔드포인트 프로토콜
public protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var body: Data? { get }
    var timeout: TimeInterval { get }
}

// MARK: - 기본 API 엔드포인트 구현
public struct DefaultAPIEndpoint: APIEndpoint {
    public let baseURL: String
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]?
    public let parameters: [String: Any]?
    public let body: Data?
    public let timeout: TimeInterval
    
    public init(
        baseURL: String,
        path: String,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        parameters: [String: Any]? = nil,
        body: Data? = nil,
        timeout: TimeInterval = 30.0
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.headers = headers
        self.parameters = parameters
        self.body = body
        self.timeout = timeout
    }
}

// MARK: - 네트워크 인터셉터 프로토콜
public protocol NetworkInterceptor {
    func interceptRequest(_ request: inout URLRequest) async throws
    func interceptResponse(_ response: HTTPURLResponse, data: Data) async throws
}

// MARK: - 인증 인터셉터
public class AuthenticationInterceptor: NetworkInterceptor {
    private let getToken: () async throws -> String
    
    public init(getToken: @escaping () async throws -> String) {
        self.getToken = getToken
    }
    
    public func interceptRequest(_ request: inout URLRequest) async throws {
        let token = try await getToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    public func interceptResponse(_ response: HTTPURLResponse, data: Data) async throws {
        if response.statusCode == 401 {
            // 토큰 만료 처리
            throw AppError.authentication(.sessionExpired)
        }
    }
}

// MARK: - 로깅 인터셉터
public class LoggingInterceptor: NetworkInterceptor {
    @Dependency(\.logger) var logger
    
    public init() {}
    
    public func interceptRequest(_ request: inout URLRequest) async throws {
        logger.logNetwork(.debug, "HTTP 요청 시작", additionalData: [
            "url": request.url?.absoluteString ?? "unknown",
            "method": request.httpMethod ?? "unknown",
            "headers": request.allHTTPHeaderFields ?? [:],
            "body_size": request.httpBody?.count ?? 0
        ])
    }
    
    public func interceptResponse(_ response: HTTPURLResponse, data: Data) async throws {
        logger.logNetwork(.debug, "HTTP 응답 수신", additionalData: [
            "status_code": response.statusCode,
            "url": response.url?.absoluteString ?? "unknown",
            "response_size": data.count,
            "headers": response.allHeaderFields
        ])
    }
}

// MARK: - 네트워크 모니터
public class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    @Published public var networkStatus: NetworkStatus = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.coby.ssafyhub.networkmonitor")
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    let connectionType: NetworkStatus.ConnectionType
                    if path.usesInterfaceType(.wifi) {
                        connectionType = .wifi
                    } else if path.usesInterfaceType(.cellular) {
                        connectionType = .cellular
                    } else if path.usesInterfaceType(.wiredEthernet) {
                        connectionType = .ethernet
                    } else {
                        connectionType = .other
                    }
                    self?.networkStatus = .connected(connectionType)
                } else {
                    self?.networkStatus = .disconnected
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - 중앙화된 네트워크 관리자
public class NetworkManager {
    public static let shared = NetworkManager()
    
    private let session: URLSession
    private let interceptors: [NetworkInterceptor]
    private let networkMonitor: NetworkMonitor
    
    @Dependency(\.logger) var logger
    @Dependency(\.errorHandler) var errorHandler
    @Dependency(\.cacheManager) var cacheManager
    
    private init() {
        // URLSession 설정
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        
        // 인터셉터 설정
        self.interceptors = [
            LoggingInterceptor()
        ]
        
        self.networkMonitor = NetworkMonitor.shared
        
        logger.logNetwork(.info, "NetworkManager 초기화 완료")
    }
    
    // MARK: - 공개 메서드
    public func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type, useCache: Bool = true) async throws -> T {
        // GET 요청이고 캐시 사용이 활성화된 경우 캐시 확인
        if endpoint.method == .GET && useCache {
            if let cachedResponse = await cacheManager.getCachedResponse(responseType, for: endpoint) {
                logger.logNetwork(.debug, "캐시된 응답 사용", additionalData: [
                    "url": endpoint.baseURL + endpoint.path
                ])
                return cachedResponse
            }
        }
        
        // 네트워크 연결 상태 확인
        guard networkMonitor.networkStatus != .disconnected else {
            // 오프라인 상태에서 캐시된 데이터가 있는지 확인
            if useCache {
                if let cachedResponse = await cacheManager.getCachedResponse(responseType, for: endpoint) {
                    logger.logNetwork(.info, "오프라인 상태에서 캐시된 응답 사용", additionalData: [
                        "url": endpoint.baseURL + endpoint.path
                    ])
                    return cachedResponse
                }
            }
            throw AppError.network(.noConnection)
        }
        
        // URLRequest 생성
        var request = try buildURLRequest(from: endpoint)
        
        // 인터셉터 적용
        for interceptor in interceptors {
            try await interceptor.interceptRequest(&request)
        }
        
        // 네트워크 요청 실행
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse)
        }
        
        // 응답 인터셉터 적용
        for interceptor in interceptors {
            try await interceptor.interceptResponse(httpResponse, data: data)
        }
        
        // HTTP 상태 코드 확인
        try validateHTTPResponse(httpResponse)
        
        // JSON 디코딩
        let result = try decodeResponse(data: data, responseType: responseType)
        
        // 성공한 GET 요청은 캐시에 저장
        if endpoint.method == .GET && useCache {
            await cacheManager.cacheResponse(result, for: endpoint)
            logger.logNetwork(.debug, "응답 캐시에 저장", additionalData: [
                "url": endpoint.baseURL + endpoint.path,
                "data_size": data.count
            ])
        }
        
        return result
    }
    
    public func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        // 네트워크 연결 상태 확인
        guard networkMonitor.networkStatus != .disconnected else {
            throw AppError.network(.noConnection)
        }
        
        // URLRequest 생성
        var request = try buildURLRequest(from: endpoint)
        
        // 인터셉터 적용
        for interceptor in interceptors {
            try await interceptor.interceptRequest(&request)
        }
        
        // 네트워크 요청 실행
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse)
        }
        
        // 응답 인터셉터 적용
        for interceptor in interceptors {
            try await interceptor.interceptResponse(httpResponse, data: data)
        }
        
        // HTTP 상태 코드 확인
        try validateHTTPResponse(httpResponse)
        
        return data
    }
    
    // MARK: - URLRequest 빌드
    private func buildURLRequest(from endpoint: APIEndpoint) throws -> URLRequest {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw AppError.network(.requestFailed("Invalid URL"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout
        
        // 헤더 설정
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 기본 헤더 설정
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 쿼리 파라미터 설정
        if let parameters = endpoint.parameters, !parameters.isEmpty {
            if endpoint.method == .GET {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.queryItems = parameters.map { key, value in
                    URLQueryItem(name: key, value: String(describing: value))
                }
                request.url = components?.url
            } else {
                // POST, PUT 등의 경우 body에 JSON으로 설정
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            }
        }
        
        // Body 설정
        if let body = endpoint.body {
            request.httpBody = body
        }
        
        return request
    }
    
    // MARK: - HTTP 응답 검증
    private func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            // 성공
            break
        case 400...499:
            // 클라이언트 에러
            if response.statusCode == 429 {
                throw AppError.network(.rateLimitExceeded)
            } else {
                throw AppError.network(.serverError(response.statusCode))
            }
        case 500...599:
            // 서버 에러
            throw AppError.network(.serverError(response.statusCode))
        default:
            throw AppError.network(.serverError(response.statusCode))
        }
    }
    
    // MARK: - 응답 디코딩
    private func decodeResponse<T: Codable>(data: Data, responseType: T.Type) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(responseType, from: data)
        } catch {
            logger.logNetwork(.error, "JSON 디코딩 실패", additionalData: [
                "error": error.localizedDescription,
                "data_size": data.count,
                "data_preview": String(data: data.prefix(200), encoding: .utf8) ?? "invalid_utf8"
            ])
            throw AppError.data(.parsingFailed)
        }
    }
    
    // MARK: - 인터셉터 관리
    public func addInterceptor(_ interceptor: NetworkInterceptor) {
        // 인터셉터 추가 로직 (현재는 초기화 시에만 설정)
    }
    
    public func removeInterceptor(_ interceptor: NetworkInterceptor) {
        // 인터셉터 제거 로직 (현재는 초기화 시에만 설정)
    }
}

// MARK: - Dependencies 통합
extension DependencyValues {
    var networkManager: NetworkManager {
        get { self[NetworkManagerKey.self] }
        set { self[NetworkManagerKey.self] = newValue }
    }
    
    var networkMonitor: NetworkMonitor {
        get { self[NetworkMonitorKey.self] }
        set { self[NetworkMonitorKey.self] = newValue }
    }
}

private enum NetworkManagerKey: DependencyKey {
    static let liveValue: NetworkManager = NetworkManager.shared
}

private enum NetworkMonitorKey: DependencyKey {
    static let liveValue: NetworkMonitor = NetworkMonitor.shared
}

// MARK: - 편의 메서드
public extension NetworkManager {
    /// GET 요청
    static func get<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        return try await shared.request(endpoint, responseType: responseType)
    }
    
    /// POST 요청
    static func post<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        return try await shared.request(endpoint, responseType: responseType)
    }
    
    /// PUT 요청
    static func put<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        return try await shared.request(endpoint, responseType: responseType)
    }
    
    /// DELETE 요청
    static func delete<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        return try await shared.request(endpoint, responseType: responseType)
    }
    
    /// 데이터 요청 (JSON 디코딩 없음)
    static func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        return try await shared.requestData(endpoint)
    }
}
