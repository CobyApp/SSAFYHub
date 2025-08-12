import Foundation

// MARK: - User
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
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
