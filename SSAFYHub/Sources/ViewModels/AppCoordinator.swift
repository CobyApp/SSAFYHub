import SwiftUI
import Foundation
import SharedModels

@MainActor
class AppCoordinator: ObservableObject {
    @Published var currentRoute: AppRoute = .auth
    @Published var navigationPath = NavigationPath()
    @Published var selectedCampus: Campus = .daejeon
    
    // MARK: - App Routes
    enum AppRoute: Hashable {
        case loading
        case auth
        case mainMenu
        case settings
    }
    
    // MARK: - 초기화
    init() {
        print("🧭 Coordinator 초기화됨")
        // 초기에는 로딩 상태로 설정하여 세션 체크 완료까지 대기
        self.currentRoute = .loading
        self.selectedCampus = Campus.default // 기본값을 대전으로 설정
        print("🏫 기본 캠퍼스 설정: \(selectedCampus.displayName)")
    }
    
    // MARK: - Navigation Methods with Smart Logic
    func navigateToMainMenu() {
        print("🧭 Coordinator: 메인 메뉴 화면으로 이동")
        currentRoute = .mainMenu
    }
    
    func navigateToAuth() {
        print("🧭 Coordinator: 인증 화면으로 이동")
        currentRoute = .auth
    }
    
    func resetToAuth() {
        print("🧭 Coordinator: 인증 화면으로 리셋")
        currentRoute = .auth
        navigationPath = NavigationPath()
    }
    
    // MARK: - Smart Navigation Methods
    func navigateToMainMenuWithCampus(_ campus: Campus) {
        print("🧭 Coordinator: 캠퍼스 \(campus.displayName)로 메인 메뉴 이동")
        currentRoute = .mainMenu
    }
    
    // MARK: - Smart Navigation for Existing Users
    func handleUserAuthentication(_ user: AppUser) {
        print("🧭 Coordinator: 사용자 인증 처리 - \(user.email)")
        
        // 모든 사용자는 바로 메인화면으로 이동
        print("✅ 사용자 인증 완료, 메인화면으로 이동")
        navigateToMainMenuWithCampus(user.campus)
    }
    
    // MARK: - Settings Navigation
    func navigateToSettings() {
        print("🧭 Coordinator: 설정 화면으로 이동")
        currentRoute = .settings
    }
    
    func navigateBackFromSettings() {
        print("🧭 Coordinator: 설정 화면에서 뒤로 이동")
        currentRoute = .mainMenu
    }
    
    // MARK: - Direct Navigation from Auth
    func handleDirectAuthentication(_ user: AppUser) {
        print("🧭 Coordinator: 직접 인증 처리 - \(user.email)")
        
        // 즉시 메인화면으로 이동 (Apple 로그인 성공 시)
        print("✅ 직접 인증 성공, 메인화면으로 이동")
        navigateToMainMenuWithCampus(user.campus)
    }
}

// MARK: - Navigation Path Extensions
extension AppCoordinator {
    func push(_ route: AppRoute) {
        currentRoute = route
    }
    
    func pop() {
        currentRoute = .auth
    }
    
    func popToRoot() {
        currentRoute = .auth
    }
}
