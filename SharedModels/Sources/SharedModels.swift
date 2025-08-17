import Foundation
import SwiftUI

// MARK: - Campus Model
public enum Campus: String, Codable, CaseIterable {
    case seoul = "seoul"
    case daejeon = "daejeon"
    case gwangju = "gwangju"
    case gumi = "gumi"
    case busan = "busan"
    
    public var displayName: String {
        switch self {
        case .seoul: return "서울캠퍼스"
        case .daejeon: return "대전캠퍼스"
        case .gwangju: return "광주캠퍼스"
        case .gumi: return "구미캠퍼스"
        case .busan: return "부산캠퍼스"
        }
    }
    
    public var isAvailable: Bool {
        switch self {
        case .daejeon:
            return true
        default:
            return false
        }
    }
    
    public var statusMessage: String {
        switch self {
        case .daejeon:
            return "지원됨"
        default:
            return "준비중 (추후 확장 예정)"
        }
    }
    
    public var description: String {
        switch self {
        case .daejeon:
            return "현재 지원되는 캠퍼스입니다."
        default:
            return "현재 준비중이며, 추후 확장 예정입니다."
        }
    }
    
    // 기본 캠퍼스는 대전
    public static var `default`: Campus {
        return .daejeon
    }
}

// MARK: - User Type
public enum UserType: String, Codable, CaseIterable {
    case guest = "guest"
    case authenticated = "authenticated"
    
    public var displayName: String {
        switch self {
        case .guest:
            return "게스트"
        case .authenticated:
            return "인증된 사용자"
        }
    }
    
    public var canEditMenus: Bool {
        switch self {
        case .guest:
            return false
        case .authenticated:
            return true
        }
    }
    
    public var canDeleteMenus: Bool {
        switch self {
        case .guest:
            return false
        case .authenticated:
            return true
        }
    }
    
    public var canManageUsers: Bool {
        switch self {
        case .guest:
            return false
        case .authenticated:
            return true
        }
    }
}

// MARK: - AppUser Model
public struct AppUser: Codable, Identifiable {
    public let id: String
    public let email: String
    public let campus: Campus
    public let userType: UserType
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(id: String, email: String, campus: Campus, userType: UserType = .authenticated, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.email = email
        self.campus = campus
        self.userType = userType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Convenience Methods
    public var isGuest: Bool {
        return userType == .guest
    }
    
    public var isAuthenticated: Bool {
        return userType == .authenticated
    }
    
    public var canEditMenus: Bool {
        return userType.canEditMenus
    }
    
    public var canDeleteMenus: Bool {
        return userType.canDeleteMenus
    }
    
    public var canManageUsers: Bool {
        return userType.canManageUsers
    }
}

// MARK: - MealMenu Model
public struct MealMenu: Codable, Identifiable {
    public let id: String
    public let date: Date
    public let campus: Campus
    public let itemsA: [String]
    public let itemsB: [String]
    public let updatedAt: Date
    public let updatedBy: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case campus = "campus_id"
        case itemsA = "items_a"
        case itemsB = "items_b"
        case updatedAt = "updated_at"
        case updatedBy = "updated_by"
    }
    
    public init(id: String, date: Date, campus: Campus, itemsA: [String], itemsB: [String], updatedAt: Date, updatedBy: String?) {
        self.id = id
        self.date = date
        self.campus = campus
        self.itemsA = itemsA
        self.itemsB = itemsB
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        
        // 날짜 필드 디코딩 개선 - 문자열과 숫자 모두 지원
        var parsedDate: Date?
        
        do {
            // 먼저 문자열로 시도
            let dateString = try container.decode(String.self, forKey: .date)
            
            // 여러 날짜 형식 시도
            let dateFormatters = [
                "yyyy-MM-dd",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ"
            ]
            
            for format in dateFormatters {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.timeZone = TimeZone.current
                
                if let date = formatter.date(from: dateString) {
                    parsedDate = date
                    break
                }
            }
        } catch {
            // 문자열 디코딩 실패 시 숫자로 시도 (TimeInterval)
            do {
                let timeInterval = try container.decode(TimeInterval.self, forKey: .date)
                parsedDate = Date(timeIntervalSince1970: timeInterval)
            } catch {
                // 숫자도 실패 시 현재 시간 사용
                parsedDate = Date()
            }
        }
        
        if let parsedDate = parsedDate {
            date = parsedDate
        } else {
            date = Date()
        }
        
        // campus_id 필드가 누락된 경우 기본값 사용
        do {
            campus = try container.decode(Campus.self, forKey: .campus)
        } catch {
            campus = .daejeon
        }
        
        // items_a 필드가 누락된 경우 기본값 사용
        do {
            itemsA = try container.decode([String].self, forKey: .itemsA)
        } catch {
            itemsA = []
        }
        
        // items_b 필드가 누락된 경우 기본값 사용
        do {
            itemsB = try container.decode([String].self, forKey: .itemsB)
        } catch {
            itemsB = []
        }
        
        // updatedAt 필드 디코딩 개선 - 문자열과 숫자 모두 지원
        var parsedUpdatedAt: Date?
        
        do {
            // 먼저 문자열로 시도
            let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let parsedDate = isoFormatter.date(from: updatedAtString) {
                parsedUpdatedAt = parsedDate
            } else {
                // ISO8601 형식이 아닌 경우 현재 시간 사용
                parsedUpdatedAt = Date()
            }
        } catch {
            // 문자열 디코딩 실패 시 숫자로 시도 (TimeInterval)
            do {
                let timeInterval = try container.decode(TimeInterval.self, forKey: .updatedAt)
                parsedUpdatedAt = Date(timeIntervalSince1970: timeInterval)
            } catch {
                // 숫자도 실패 시 현재 시간 사용
                parsedUpdatedAt = Date()
            }
        }
        
        if let parsedUpdatedAt = parsedUpdatedAt {
            updatedAt = parsedUpdatedAt
        } else {
            updatedAt = Date()
        }
        
        updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
    }
}

// MARK: - MealMenu Input Models
public struct MealMenuInput: Codable {
    public let date: Date
    public let campus: Campus
    public let itemsA: [String]
    public let itemsB: [String]
    
    enum CodingKeys: String, CodingKey {
        case date
        case campus = "campus_id"
        case itemsA = "items_a"
        case itemsB = "items_b"
    }
    
    public init(date: Date, campus: Campus, itemsA: [String], itemsB: [String]) {
        self.date = date
        self.campus = campus
        self.itemsA = itemsA
        self.itemsB = itemsB
    }
}

public struct WeeklyMealMenuInput: Codable {
    public let startDate: Date
    public let campus: Campus
    public let weeklyMenus: [DailyMealMenu]
    
    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case campus = "campus_id"
        case weeklyMenus = "weekly_menus"
    }
    
    public init(startDate: Date, campus: Campus, weeklyMenus: [DailyMealMenu]) {
        self.startDate = startDate
        self.campus = campus
        self.weeklyMenus = weeklyMenus
    }
}

public struct DailyMealMenu: Codable {
    public let date: Date
    public let itemsA: [String]
    public let itemsB: [String]
    
    enum CodingKeys: String, CodingKey {
        case date
        case itemsA = "items_a"
        case itemsB = "items_b"
    }
    
    public init(date: Date, itemsA: [String], itemsB: [String]) {
        self.date = date
        self.itemsA = itemsA
        self.itemsB = itemsB
    }
}

// MARK: - Widget Colors
public struct WidgetColors {
    // 위젯 전용 색상 (고정 색상)
    public static let widgetABackground = Color(red: 0.2, green: 0.6, blue: 1.0)  // A타입: 파란색
    public static let widgetBBackground = Color(red: 0.2, green: 0.8, blue: 0.4)  // B타입: 초록색
}

// MARK: - Auth State
public enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated(AppUser)
    
    // Equatable 준수를 위한 구현
    public static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser.id == rhsUser.id
        default:
            return false
        }
    }
}
