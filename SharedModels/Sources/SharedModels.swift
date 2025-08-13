import Foundation

// MARK: - Menu Model (위젯과 메인 앱에서 공유)
public struct Menu: Codable {
    public let id: String
    public let date: Date
    public let campus: Campus
    public let itemsA: [String]
    public let itemsB: [String]
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(id: String, date: Date, campus: Campus, itemsA: [String], itemsB: [String], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.date = date
        self.campus = campus
        self.itemsA = itemsA
        self.itemsB = itemsB
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum Campus: String, Codable, CaseIterable {
    case daejeon = "daejeon"
    case gwangju = "gwangju"
    case gumi = "gumi"
    case seoul = "seoul"
    case busan = "busan"
    
    public var displayName: String {
        switch self {
        case .daejeon: return "대전"
        case .gwangju: return "광주"
        case .gumi: return "구미"
        case .seoul: return "서울"
        case .busan: return "부산"
        }
    }
}
