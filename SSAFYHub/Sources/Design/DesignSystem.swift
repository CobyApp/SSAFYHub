import SwiftUI

// MARK: - Color System
struct AppColors {
    // SSAFY 브랜드 컬러
    static let ssafyBlue = Color(red: 0.2, green: 0.6, blue: 1.0)  // #3399FF
    static let ssafyBlueLight = Color(red: 0.4, green: 0.7, blue: 1.0)  // #66B3FF
    static let ssafyBlueDark = Color(red: 0.1, green: 0.4, blue: 0.8)  // #1A66CC
    
    // 기본 컬러
    static let primary = ssafyBlue
    static let primaryLight = ssafyBlueLight
    static let primaryDark = ssafyBlueDark
    
    // 보조 컬러
    static let secondary = Color(red: 0.95, green: 0.95, blue: 0.97)  // #F2F2F7
    static let secondaryDark = Color(red: 0.15, green: 0.15, blue: 0.17)  // #262628
    
    // 배경 컬러
    static let background = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    
    // 텍스트 컬러
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // 상태 컬러
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)  // #33CC66
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)  // #FF9900
    static let error = Color(red: 1.0, green: 0.3, blue: 0.3)   // #FF4D4D
    
    // 그라데이션
    static let primaryGradient = LinearGradient(
        colors: [ssafyBlue, ssafyBlueLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [background, secondary],
        startPoint: .top,
        endPoint: .bottom
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
    
    init() {
        // 시스템 설정에 따라 초기 테마 설정
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            isDarkMode = windowScene.traitCollection.userInterfaceStyle == .dark
        }
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
    
    // 현재 테마에 따른 색상 반환
    var currentBackground: Color {
        isDarkMode ? AppColors.background : AppColors.background
    }
    
    var currentBackgroundSecondary: Color {
        isDarkMode ? AppColors.backgroundSecondary : AppColors.backgroundSecondary
    }
    
    var currentTextPrimary: Color {
        isDarkMode ? AppColors.textPrimary : AppColors.textPrimary
    }
    
    var currentTextSecondary: Color {
        isDarkMode ? AppColors.textSecondary : AppColors.textSecondary
    }
}
