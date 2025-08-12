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
