import Foundation

// MARK: - Campus
enum Campus: String, CaseIterable, Codable {
    case seoul = "seoul"
    case daejeon = "daejeon"
    case gwangju = "gwangju"
    case gumi = "gumi"
    case busan = "busan"
    
    var displayName: String {
        switch self {
        case .seoul:
            return "서울캠퍼스"
        case .daejeon:
            return "대전캠퍼스"
        case .gwangju:
            return "광주캠퍼스"
        case .gumi:
            return "구미캠퍼스"
        case .busan:
            return "부산캠퍼스"
        }
    }
    
    var description: String {
        switch self {
        case .seoul:
            return "서울특별시 강남구 테헤란로 501"
        case .daejeon:
            return "대전광역시 유성구 동서대로 125"
        case .gwangju:
            return "광주광역시 광산구 상무대로 312"
        case .gumi:
            return "경상북도 구미시 구미대로 123"
        case .busan:
            return "부산광역시 해운대구 센텀중앙로 97"
        }
    }
}
