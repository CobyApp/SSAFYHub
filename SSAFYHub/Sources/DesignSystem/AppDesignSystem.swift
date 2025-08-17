import SwiftUI

// MARK: - Color System
struct AppColors {
    // SSAFY 브랜드 컬러 (고정 색상)
    static let ssafyBlue = Color(red: 0.2, green: 0.6, blue: 1.0)  // #3399FF
    static let ssafyBlueLight = Color(red: 0.4, green: 0.7, blue: 1.0)  // #66B3FF
    static let ssafyBlueDark = Color(red: 0.1, green: 0.4, blue: 0.8)  // #1A66CC
    
    // 기본 컬러
    static let primary = ssafyBlue
    static let primaryLight = ssafyBlueLight
    static let primaryDark = ssafyBlueDark
    
    // 보조 컬러
    static let secondary = Color(.systemGray6)
    static let secondaryDark = Color(.systemGray5)
    
    // 배경 컬러 - 다크모드 자동 지원
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    
    // 텍스트 컬러 - 다크모드 자동 지원
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // 상태 컬러
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)  // #33CC66
    static let successLight = Color(red: 0.3, green: 0.9, blue: 0.5)  // #4DDB7A
    static let successDark = Color(red: 0.1, green: 0.7, blue: 0.3)  // #1AB34D
    
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)  // #FF9900
    static let warningLight = Color(red: 1.0, green: 0.7, blue: 0.2)  // #FFB333
    static let warningDark = Color(red: 0.8, green: 0.5, blue: 0.0)  // #CC7A00
    
    static let error = Color(red: 1.0, green: 0.3, blue: 0.3)   // #FF4D4D
    static let errorLight = Color(red: 1.0, green: 0.4, blue: 0.4)   // #FF6666
    static let errorDark = Color(red: 0.8, green: 0.2, blue: 0.2)   // #CC3333
    
    static let disabled = Color(.systemGray3)
    static let border = Color(.separator)
    
    // 위젯 전용 색상 (고정 색상)
    static let widgetABackground = Color(red: 0.2, green: 0.6, blue: 1.0)  // A타입: 파란색
    static let widgetBBackground = Color(red: 0.2, green: 0.8, blue: 0.4)  // B타입: 초록색
    
    // 그라데이션
    static let primaryGradient = LinearGradient(
        colors: [ssafyBlue, ssafyBlueLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [backgroundPrimary, backgroundSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let successGradient = LinearGradient(
        colors: [success, successLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let errorGradient = LinearGradient(
        colors: [error, errorLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography System
struct AppTypography {
    // 프리텐다드 폰트 패밀리
    static let fontFamily = "Pretendard"
    
    // 제목 스타일
    static let largeTitle = Font.custom(fontFamily, size: 34).weight(.bold)
    static let title1 = Font.custom(fontFamily, size: 28).weight(.bold)
    static let title2 = Font.custom(fontFamily, size: 22).weight(.semibold)
    static let title3 = Font.custom(fontFamily, size: 20).weight(.semibold)
    
    // 본문 스타일
    static let headline = Font.custom(fontFamily, size: 17).weight(.semibold)
    static let body = Font.custom(fontFamily, size: 17).weight(.regular)
    static let callout = Font.custom(fontFamily, size: 16).weight(.regular)
    static let subheadline = Font.custom(fontFamily, size: 15).weight(.regular)
    static let footnote = Font.custom(fontFamily, size: 13).weight(.regular)
    static let caption1 = Font.custom(fontFamily, size: 12).weight(.regular)
    static let caption2 = Font.custom(fontFamily, size: 11).weight(.regular)
}

// MARK: - Spacing System
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius System
struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
    static let pill: CGFloat = 25
}

// MARK: - Shadow System
struct AppShadow {
    static let small = Shadow(
        color: Color.black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let medium = Shadow(
        color: Color.black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )
    
    static let large = Shadow(
        color: Color.black.opacity(0.2),
        radius: 16,
        x: 0,
        y: 8
    )
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                configuration.isPressed ? AppColors.primaryDark : AppColors.primary
            )
            .cornerRadius(AppCornerRadius.pill)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                configuration.isPressed ? AppColors.secondary : AppColors.secondary.opacity(0.5)
            )
            .cornerRadius(AppCornerRadius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.pill)
                    .stroke(AppColors.primary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.subheadline)
            .foregroundColor(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                configuration.isPressed ? AppColors.secondary : Color.clear
            )
            .cornerRadius(AppCornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Style
struct AppCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppCornerRadius.medium)
            .shadow(
                color: AppShadow.small.color,
                radius: AppShadow.small.radius,
                x: AppShadow.small.x,
                y: AppShadow.small.y
            )
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardStyle())
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var themeMode: ThemeMode = .system
    
    enum ThemeMode: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light: return "라이트"
            case .dark: return "다크"
            case .system: return "시스템"
            }
        }
    }
    
    init() {
        // UserDefaults에서 저장된 테마 설정 불러오기
        if let savedTheme = UserDefaults.standard.string(forKey: "app.theme") {
            themeMode = ThemeMode(rawValue: savedTheme) ?? .system
        }
        
        // 앱 시작 시 테마 설정을 시스템에 즉시 적용
        DispatchQueue.main.async {
            self.updateTheme()
        }
    }
    
    // 현재 테마 모드에 따른 다크모드 여부 계산
    private var shouldUseDarkMode: Bool {
        switch themeMode {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return windowScene.traitCollection.userInterfaceStyle == .dark
            }
            return false
        }
    }
    
    // 테마 업데이트 및 시스템에 적용
    private func updateTheme() {
        isDarkMode = shouldUseDarkMode
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let userInterfaceStyle: UIUserInterfaceStyle
            switch themeMode {
            case .light:
                userInterfaceStyle = .light
            case .dark:
                userInterfaceStyle = .dark
            case .system:
                userInterfaceStyle = .unspecified
            }
            
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = userInterfaceStyle
            }
        }
    }
    
    // 테마 모드 변경
    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "app.theme")
        updateTheme()
    }
    
    // 테마 토글 (라이트 ↔ 다크)
    func toggleTheme() {
        let newMode: ThemeMode
        switch themeMode {
        case .light:
            newMode = .dark
        case .dark:
            newMode = .light
        case .system:
            newMode = shouldUseDarkMode ? .light : .dark
        }
        setThemeMode(newMode)
    }
    
    // 시스템 테마 변경 감지
    func systemThemeChanged() {
        if themeMode == .system {
            updateTheme()
        }
    }
    
    // 현재 테마에 따른 색상 반환 (다크모드 자동 지원)
    var currentBackground: Color {
        AppColors.backgroundPrimary
    }
    
    var currentBackgroundSecondary: Color {
        AppColors.backgroundSecondary
    }
    
    var currentTextPrimary: Color {
        AppColors.textPrimary
    }
    
    var currentTextSecondary: Color {
        AppColors.textSecondary
    }
}
