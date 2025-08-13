import Foundation
import SharedModels

// MARK: - Campus Extension
extension Campus {
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
    
    var isAvailable: Bool {
        switch self {
        case .daejeon:
            return true
        default:
            return false
        }
    }
    
    var statusMessage: String {
        switch self {
        case .daejeon:
            return "지원됨"
        default:
            return "준비중 (추후 확장 예정)"
        }
    }
    
    var description: String {
        switch self {
        case .daejeon:
            return "현재 지원되는 캠퍼스입니다."
        default:
            return "현재 준비중이며, 추후 확장 예정입니다."
        }
    }
    
    // 기본 캠퍼스는 대전
    static var `default`: Campus {
        return .daejeon
    }
}
