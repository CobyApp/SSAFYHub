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
