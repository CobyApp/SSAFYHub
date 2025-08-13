import Foundation
import SharedModels

// MARK: - User Type
enum UserType: String, Codable, CaseIterable {
    case guest = "guest"
    case authenticated = "authenticated"
    
    var displayName: String {
        switch self {
        case .guest:
            return "게스트"
        case .authenticated:
            return "인증된 사용자"
        }
    }
    
    var canEditMenus: Bool {
        switch self {
        case .guest:
            return false
        case .authenticated:
            return true
        }
    }
    
    var canDeleteMenus: Bool {
        switch self {
        case .guest:
            return false
        case .authenticated:
            return true
        }
    }
    
    var canManageUsers: Bool {
        switch self {
        case .guest:
            return false
        case .authenticated:
            return true
        }
    }
}

// MARK: - User
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let campus: Campus
    let userType: UserType
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case campus = "campus_id"
        case userType = "user_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Initializers
    init(id: String, email: String, campus: Campus, userType: UserType = .authenticated, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.email = email
        self.campus = campus
        self.userType = userType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Convenience Methods
    var isGuest: Bool {
        return userType == .guest
    }
    
    var isAuthenticated: Bool {
        return userType == .authenticated
    }
    
    var canEditMenus: Bool {
        return userType.canEditMenus
    }
    
    var canDeleteMenus: Bool {
        return userType.canDeleteMenus
    }
    
    var canManageUsers: Bool {
        return userType.canManageUsers
    }
}
