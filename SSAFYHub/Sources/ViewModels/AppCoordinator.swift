import SwiftUI
import Foundation
import SharedModels

@MainActor
class AppCoordinator: ObservableObject {
    @Published var currentRoute: AppRoute = .auth
    @Published var navigationPath = NavigationPath()
    @Published var transitionAnimation: Animation = .easeInOut(duration: 0.3)
    @Published var selectedCampus: Campus = .daejeon
    
    // MARK: - App Routes
    enum AppRoute: Hashable {
        case auth
        case mainMenu
        case settings
    }
    
    // MARK: - 초기화
    init() {
        print("🧭 Coordinator 초기화됨")
        self.currentRoute = .auth
        self.selectedCampus = Campus.default // 기본값을 대전으로 설정
        print("🏫 기본 캠퍼스 설정: \(selectedCampus.displayName)")
    }
    
    // MARK: - Navigation Methods with Smart Logic
    func navigateToMainMenu() {
        print("🧭 Coordinator: 메인 메뉴 화면으로 이동")
        withAnimation(transitionAnimation) {
            currentRoute = .mainMenu
        }
    }
    
    func navigateToAuth() {
        print("🧭 Coordinator: 인증 화면으로 이동")
        withAnimation(transitionAnimation) {
            currentRoute = .auth
        }
    }
    
    func resetToAuth() {
        print("🧭 Coordinator: 인증 화면으로 리셋")
        withAnimation(transitionAnimation) {
            currentRoute = .auth
            navigationPath = NavigationPath()
        }
    }
    
    // MARK: - Smart Navigation Methods
    func navigateToMainMenuWithCampus(_ campus: Campus) {
        print("🧭 Coordinator: 캠퍼스 \(campus.displayName)로 메인 메뉴 이동")
        withAnimation(transitionAnimation) {
            currentRoute = .mainMenu
        }
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
        withAnimation(transitionAnimation) {
            currentRoute = .settings
        }
    }
    
    func navigateBackFromSettings() {
        print("🧭 Coordinator: 설정 화면에서 뒤로 이동")
        withAnimation(transitionAnimation) {
            currentRoute = .mainMenu
        }
    }
    
    // MARK: - Direct Navigation from Auth
    func handleDirectAuthentication(_ user: AppUser) {
        print("🧭 Coordinator: 직접 인증 처리 - \(user.email)")
        
        // 즉시 메인화면으로 이동 (Apple 로그인 성공 시)
        print("✅ 직접 인증 성공, 메인화면으로 이동")
        navigateToMainMenuWithCampus(user.campus)
    }
    
    // MARK: - Animation Customization
    func setTransitionAnimation(_ animation: Animation) {
        transitionAnimation = animation
    }
}

// MARK: - Navigation Path Extensions
extension AppCoordinator {
    func push(_ route: AppRoute) {
        withAnimation(transitionAnimation) {
            navigationPath.append(route)
        }
    }
    
    func pop() {
        withAnimation(transitionAnimation) {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        withAnimation(transitionAnimation) {
            navigationPath.removeLast(navigationPath.count)
        }
    }
}
