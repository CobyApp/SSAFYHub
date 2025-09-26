import Foundation
import IdentifiedCollections

public struct MenuItem: Identifiable, Equatable, Codable {
    public let id: UUID
    public var text: String
    public var mealType: MealType
    
    public init(id: UUID = UUID(), text: String, mealType: MealType) {
        self.id = id
        self.text = text
        self.mealType = mealType
    }
}

public enum MealType: String, CaseIterable, Codable, Equatable {
    case a = "A"
    case b = "B"
    
    public var displayName: String {
        switch self {
        case .a:
            return "A타입"
        case .b:
            return "B타입"
        }
    }
    
    public var color: String {
        switch self {
        case .a:
            return "accentPrimary"
        case .b:
            return "accentSecondary"
        }
    }
}
