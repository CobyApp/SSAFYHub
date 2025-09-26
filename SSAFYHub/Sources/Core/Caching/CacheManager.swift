import Foundation
import Dependencies
import SharedModels

// MARK: - 캐시 정책
public struct CachePolicy {
    public let expirationTime: TimeInterval
    public let maxMemorySize: Int // 바이트 단위
    public let maxDiskSize: Int // 바이트 단위
    
    public static let `default` = CachePolicy(
        expirationTime: 300, // 5분
        maxMemorySize: 50 * 1024 * 1024, // 50MB
        maxDiskSize: 200 * 1024 * 1024 // 200MB
    )
    
    public static let shortTerm = CachePolicy(
        expirationTime: 60, // 1분
        maxMemorySize: 10 * 1024 * 1024, // 10MB
        maxDiskSize: 50 * 1024 * 1024 // 50MB
    )
    
    public static let longTerm = CachePolicy(
        expirationTime: 3600, // 1시간
        maxMemorySize: 100 * 1024 * 1024, // 100MB
        maxDiskSize: 500 * 1024 * 1024 // 500MB
    )
}

// MARK: - 캐시 엔트리
public struct CacheEntry<T: Codable>: Codable {
    public let value: T
    public let timestamp: Date
    public let expirationTime: Date
    public let accessCount: Int
    public let lastAccessDate: Date
    
    public init(value: T, expirationTime: TimeInterval) {
        self.value = value
        self.timestamp = Date()
        self.expirationTime = Date().addingTimeInterval(expirationTime)
        self.accessCount = 0
        self.lastAccessDate = Date()
    }
    
    public var isExpired: Bool {
        return Date() > expirationTime
    }
    
    public func accessed() -> CacheEntry<T> {
        return CacheEntry(
            value: value,
            expirationTime: expirationTime.timeIntervalSince(timestamp)
        )
    }
}

// MARK: - 캐시 매니저 프로토콜
public protocol CacheManagerProtocol {
    func store<T: Codable>(_ object: T, forKey key: String, policy: CachePolicy) async
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async -> T?
    func remove(forKey key: String) async
    func clear() async
    func removeExpired() async
    func getCacheInfo() async -> CacheInfo
}

// MARK: - 캐시 정보
public struct CacheInfo {
    public let memoryEntryCount: Int
    public let diskEntryCount: Int
    public let memorySize: Int
    public let diskSize: Int
    public let hitRate: Double
    
    public init(memoryEntryCount: Int, diskEntryCount: Int, memorySize: Int, diskSize: Int, hitRate: Double) {
        self.memoryEntryCount = memoryEntryCount
        self.diskEntryCount = diskEntryCount
        self.memorySize = memorySize
        self.diskSize = diskSize
        self.hitRate = hitRate
    }
}

// MARK: - 중앙화된 캐시 매니저
public class CacheManager: CacheManagerProtocol {
    public static let shared = CacheManager()
    
    // 메모리 캐시
    private let memoryCache = NSCache<NSString, NSData>()
    
    // 디스크 캐시 디렉토리
    private let cacheDirectory: URL
    
    // 통계
    private var hitCount: Int = 0
    private var missCount: Int = 0
    
    @Dependency(\.logger) var logger
    
    private init() {
        // 캐시 디렉토리 설정
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("Cache")
        
        // 캐시 디렉토리 생성
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // 메모리 캐시 설정
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        logger.logData(.info, "CacheManager 초기화 완료", additionalData: [
            "cache_directory": cacheDirectory.path,
            "memory_limit": "50MB"
        ])
    }
    
    // MARK: - 공개 메서드
    public func store<T: Codable>(_ object: T, forKey key: String, policy: CachePolicy = .default) async {
        do {
            let entry = CacheEntry(value: object, expirationTime: policy.expirationTime)
            let data = try JSONEncoder().encode(entry)
            
            // 메모리 캐시에 저장
            let memoryKey = NSString(string: key)
            memoryCache.setObject(data as NSData, forKey: memoryKey)
            
            // 디스크 캐시에 저장
            let diskURL = cacheDirectory.appendingPathComponent("\(key).cache")
            try data.write(to: diskURL)
            
            logger.logData(.debug, "캐시 저장 완료", additionalData: [
                "key": key,
                "data_size": data.count,
                "expiration_time": policy.expirationTime
            ])
            
        } catch {
            logger.logData(.error, "캐시 저장 실패", additionalData: [
                "key": key,
                "error": error.localizedDescription
            ])
        }
    }
    
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async -> T? {
        // 먼저 메모리 캐시에서 확인
        let memoryKey = NSString(string: key)
        if let memoryData = memoryCache.object(forKey: memoryKey) {
            if let entry = try? JSONDecoder().decode(CacheEntry<T>.self, from: memoryData as Data) {
                if !entry.isExpired {
                    hitCount += 1
                    logger.logData(.debug, "메모리 캐시 히트", additionalData: [
                        "key": key,
                        "access_count": entry.accessCount + 1
                    ])
                    
                    // 접근 정보 업데이트
                    let updatedEntry = entry.accessed()
                    if let updatedData = try? JSONEncoder().encode(updatedEntry) {
                        memoryCache.setObject(updatedData as NSData, forKey: memoryKey)
                    }
                    
                    return entry.value
                } else {
                    // 만료된 캐시 제거
                    memoryCache.removeObject(forKey: memoryKey)
                }
            }
        }
        
        // 디스크 캐시에서 확인
        let diskURL = cacheDirectory.appendingPathComponent("\(key).cache")
        if let diskData = try? Data(contentsOf: diskURL) {
            if let entry = try? JSONDecoder().decode(CacheEntry<T>.self, from: diskData) {
                if !entry.isExpired {
                    hitCount += 1
                    
                    // 메모리 캐시로 이동 (LRU)
                    memoryCache.setObject(diskData as NSData, forKey: memoryKey)
                    
                    logger.logData(.debug, "디스크 캐시 히트", additionalData: [
                        "key": key,
                        "access_count": entry.accessCount + 1
                    ])
                    
                    // 접근 정보 업데이트
                    let updatedEntry = entry.accessed()
                    if let updatedData = try? JSONEncoder().encode(updatedEntry) {
                        try? updatedData.write(to: diskURL)
                    }
                    
                    return entry.value
                } else {
                    // 만료된 캐시 제거
                    try? FileManager.default.removeItem(at: diskURL)
                }
            }
        }
        
        missCount += 1
        logger.logData(.debug, "캐시 미스", additionalData: [
            "key": key
        ])
        
        return nil
    }
    
    public func remove(forKey key: String) async {
        // 메모리 캐시에서 제거
        let memoryKey = NSString(string: key)
        memoryCache.removeObject(forKey: memoryKey)
        
        // 디스크 캐시에서 제거
        let diskURL = cacheDirectory.appendingPathComponent("\(key).cache")
        try? FileManager.default.removeItem(at: diskURL)
        
        logger.logData(.debug, "캐시 제거 완료", additionalData: [
            "key": key
        ])
    }
    
    public func clear() async {
        // 메모리 캐시 클리어
        memoryCache.removeAllObjects()
        
        // 디스크 캐시 클리어
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            logger.logData(.error, "디스크 캐시 클리어 실패", additionalData: [
                "error": error.localizedDescription
            ])
        }
        
        // 통계 리셋
        hitCount = 0
        missCount = 0
        
        logger.logData(.info, "캐시 전체 클리어 완료")
    }
    
    public func removeExpired() async {
        // 메모리 캐시에서 만료된 항목 제거
        // NSCache는 자동으로 관리되므로 수동 제거는 제한적
        
        // 디스크 캐시에서 만료된 항목 제거
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            for file in files {
                if let data = try? Data(contentsOf: file),
                   let entry = try? JSONDecoder().decode(CacheEntry<AnyCodable>.self, from: data) {
                    if entry.isExpired {
                        try FileManager.default.removeItem(at: file)
                        logger.logData(.debug, "만료된 캐시 제거", additionalData: [
                            "file": file.lastPathComponent
                        ])
                    }
                }
            }
        } catch {
            logger.logData(.error, "만료된 캐시 제거 실패", additionalData: [
                "error": error.localizedDescription
            ])
        }
    }
    
    public func getCacheInfo() async -> CacheInfo {
        let memoryEntryCount = memoryCache.countLimit
        let memorySize = memoryCache.totalCostLimit
        
        var diskEntryCount = 0
        var diskSize = 0
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            diskEntryCount = files.count
            
            for file in files {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                   let fileSize = attributes[.size] as? Int {
                    diskSize += fileSize
                }
            }
        } catch {
            logger.logData(.error, "디스크 캐시 정보 수집 실패", additionalData: [
                "error": error.localizedDescription
            ])
        }
        
        let totalRequests = hitCount + missCount
        let hitRate = totalRequests > 0 ? Double(hitCount) / Double(totalRequests) : 0.0
        
        return CacheInfo(
            memoryEntryCount: memoryEntryCount,
            diskEntryCount: diskEntryCount,
            memorySize: memorySize,
            diskSize: diskSize,
            hitRate: hitRate
        )
    }
}

// MARK: - AnyCodable (타입 제거를 위한 래퍼)
private struct AnyCodable: Codable {}

// MARK: - 캐시 키 생성 헬퍼
public extension CacheManager {
    static func key(for endpoint: APIEndpoint) -> String {
        let components = [
            endpoint.baseURL,
            endpoint.path,
            endpoint.method.rawValue,
            endpoint.parameters?.description ?? "",
            endpoint.body?.base64EncodedString() ?? ""
        ]
        return components.joined(separator: "|").md5
    }
    
    static func key(for userId: String, campus: Campus, date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "menu_\(userId)_\(campus.rawValue)_\(dateFormatter.string(from: date))"
    }
}

// MARK: - String MD5 확장
private extension String {
    var md5: String {
        let data = Data(self.utf8)
        var hash = 0
        for byte in data {
            hash = hash &+ Int(byte)
        }
        // 간단한 해시 함수 (실제 구현에서는 CryptoKit 사용 권장)
        return String(format: "%02x", hash)
    }
}

// MARK: - Dependencies 통합
extension DependencyValues {
    var cacheManager: CacheManagerProtocol {
        get { self[CacheManagerKey.self] }
        set { self[CacheManagerKey.self] = newValue }
    }
}

private enum CacheManagerKey: DependencyKey {
    static let liveValue: CacheManagerProtocol = CacheManager.shared
}

// MARK: - 편의 메서드
public extension CacheManagerProtocol {
    /// 메뉴 데이터 캐싱
    func cacheMenu(_ menu: MealMenu, for userId: String) async {
        let key = CacheManager.key(for: userId, campus: menu.campus, date: menu.date)
        await store(menu, forKey: key, policy: .longTerm)
    }
    
    /// 캐시된 메뉴 데이터 조회
    func getCachedMenu(for userId: String, campus: Campus, date: Date) async -> MealMenu? {
        let key = CacheManager.key(for: userId, campus: campus, date: date)
        return await retrieve(MealMenu.self, forKey: key)
    }
    
    /// 네트워크 요청 결과 캐싱
    func cacheResponse<T: Codable>(_ response: T, for endpoint: APIEndpoint) async {
        let key = CacheManager.key(for: endpoint)
        await store(response, forKey: key, policy: .default)
    }
    
    /// 캐시된 네트워크 응답 조회
    func getCachedResponse<T: Codable>(_ type: T.Type, for endpoint: APIEndpoint) async -> T? {
        let key = CacheManager.key(for: endpoint)
        return await retrieve(type, forKey: key)
    }
}
