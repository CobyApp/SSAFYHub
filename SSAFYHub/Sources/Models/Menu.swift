import Foundation

// MARK: - Menu
struct Menu: Codable, Identifiable {
    let id: String
    let date: Date
    let campus: Campus
    let itemsA: [String]
    let itemsB: [String]
    let updatedAt: Date
    let updatedBy: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case campus = "campus_id"
        case itemsA = "items_a"
        case itemsB = "items_b"
        case updatedAt = "updated_at"
        case updatedBy = "updated_by"
    }
    
    // MARK: - Initializers
    init(id: String, date: Date, campus: Campus, itemsA: [String], itemsB: [String], updatedAt: Date, updatedBy: String?) {
        self.id = id
        self.date = date
        self.campus = campus
        self.itemsA = itemsA
        self.itemsB = itemsB
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        
        // 날짜 필드 디코딩 개선
        let dateString = try container.decode(String.self, forKey: .date)
        print("🔍 Menu 디코딩: 날짜 문자열 - \(dateString)")
        
        // 여러 날짜 형식 시도
        let dateFormatters = [
            "yyyy-MM-dd",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ"
        ]
        
        var parsedDate: Date?
        for format in dateFormatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = TimeZone.current
            
            if let date = formatter.date(from: dateString) {
                parsedDate = date
                print("✅ Menu 디코딩: 날짜 파싱 성공 - 형식: \(format), 결과: \(date)")
                break
            }
        }
        
        if let parsedDate = parsedDate {
            date = parsedDate
        } else {
            print("❌ Menu 디코딩: 모든 날짜 형식 파싱 실패 - \(dateString)")
            throw DecodingError.dataCorruptedError(
                forKey: .date,
                in: container,
                debugDescription: "날짜 형식이 올바르지 않습니다: \(dateString)"
            )
        }
        
        // campus_id 필드가 누락된 경우 기본값 사용
        do {
            campus = try container.decode(Campus.self, forKey: .campus)
        } catch {
            print("⚠️ Menu 디코딩: campus_id 필드 누락, 기본값 대전캠퍼스 사용")
            campus = .daejeon
        }
        
        // items_a 필드가 누락된 경우 기본값 사용
        do {
            itemsA = try container.decode([String].self, forKey: .itemsA)
        } catch {
            print("⚠️ Menu 디코딩: items_a 필드 누락, 기본값 빈 배열 사용")
            itemsA = []
        }
        
        // items_b 필드가 누락된 경우 기본값 사용
        do {
            itemsB = try container.decode([String].self, forKey: .itemsB)
        } catch {
            print("⚠️ Menu 디코딩: items_b 필드 누락, 기본값 빈 배열 사용")
            itemsB = []
        }
        
        // updatedAt 필드 디코딩 개선
        do {
            let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let parsedUpdatedAt = isoFormatter.date(from: updatedAtString) {
                updatedAt = parsedUpdatedAt
            } else {
                // ISO8601 형식이 아닌 경우 현재 시간 사용
                updatedAt = Date()
            }
        } catch {
            print("⚠️ Menu 디코딩: updated_at 필드 누락, 기본값 현재 시간 사용")
            updatedAt = Date()
        }
        
        updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
    }
}

// MARK: - MenuInput
struct MenuInput: Codable {
    let date: Date
    let campus: Campus
    let itemsA: [String]
    let itemsB: [String]
    
    enum CodingKeys: String, CodingKey {
        case date
        case campus = "campus_id"
        case itemsA = "items_a"
        case itemsB = "items_b"
    }
}

// MARK: - Weekly Menu Input
struct WeeklyMenuInput: Codable {
    let startDate: Date
    let campus: Campus
    let weeklyMenus: [DailyMenu]
    
    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case campus = "campus_id"
        case weeklyMenus = "weekly_menus"
    }
}

// MARK: - Daily Menu
struct DailyMenu: Codable {
    let date: Date
    let itemsA: [String]
    let itemsB: [String]
    
    enum CodingKeys: String, CodingKey {
        case date
        case itemsA = "items_a"
        case itemsB = "items_b"
    }
}
