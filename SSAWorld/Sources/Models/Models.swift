import Foundation

// MARK: - Campus
enum Campus: String, CaseIterable, Identifiable, Codable {
    case seoul = "seoul"
    case daejeon = "daejeon"
    case gwangju = "gwangju"
    case gumi = "gumi"
    case busan = "busan"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .seoul: return "서울"
        case .daejeon: return "대전"
        case .gwangju: return "광주"
        case .gumi: return "구미"
        case .busan: return "부산"
        }
    }
}

// MARK: - User
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String?
    let campus: Campus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case campus = "campus_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Menu
struct Menu: Codable, Identifiable {
    let id: String
    let date: Date
    let campus: Campus
    let itemsA: [String]
    let itemsB: [String]
    let updatedAt: Date
    let updatedBy: String
    let revision: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case campus = "campus_id"
        case itemsA = "items_a"
        case itemsB = "items_b"
        case updatedAt = "updated_at"
        case updatedBy = "updated_by"
        case revision
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

// MARK: - AuthState
enum AuthState: Equatable {
    case loading
    case authenticated(User)
    case unauthenticated
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser == rhsUser
        default:
            return false
        }
    }
}
