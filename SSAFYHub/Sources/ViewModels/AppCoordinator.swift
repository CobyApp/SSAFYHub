import SwiftUI
import Foundation

@MainActor
class AppCoordinator: ObservableObject {
    @Published var currentRoute: AppRoute = .auth
    @Published var navigationPath = NavigationPath()
    @Published var transitionAnimation: Animation = .easeInOut(duration: 0.3)
    @Published var selectedCampus: Campus = .daejeon
    
    // MARK: - App Routes
    enum AppRoute: Hashable {
        case auth
        case campusSelection
        case mainMenu
    }
    
    // MARK: - 초기화
    init() {
        print("🧭 Coordinator 초기화됨")
        self.currentRoute = .auth
        self.selectedCampus = Campus.default // 기본값을 대전으로 설정
        print("🏫 기본 캠퍼스 설정: \(selectedCampus.displayName)")
    }
    
    // MARK: - Navigation Methods with Smart Logic
    func navigateToCampusSelection() {
        print("🧭 Coordinator: 캠퍼스 선택 화면으로 이동")
        withAnimation(transitionAnimation) {
            currentRoute = .campusSelection
        }
    }
    
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
    func handleUserAuthentication(_ user: User) {
        print("🧭 Coordinator: 사용자 인증 처리 - \(user.email)")
        
        // 사용자에게 이미 캠퍼스 정보가 있으면 바로 메인화면으로
        if !user.campus.rawValue.isEmpty {
            print("✅ 기존 캠퍼스 정보 발견: \(user.campus.displayName)")
            navigateToMainMenuWithCampus(user.campus)
        } else {
            print("❓ 캠퍼스 정보 없음, 캠퍼스 선택 화면으로 이동")
            navigateToCampusSelection()
        }
    }
    
    // MARK: - Campus Selection Completion
    func completeCampusSelection(_ campus: Campus) {
        print("🧭 Coordinator: 캠퍼스 선택 완료 - \(campus.displayName)")
        withAnimation(transitionAnimation) {
            currentRoute = .mainMenu
        }
    }
    
    // MARK: - Direct Navigation from Auth
    func handleDirectAuthentication(_ user: User) {
        print("🧭 Coordinator: 직접 인증 처리 - \(user.email)")
        
        // 즉시 메인화면으로 이동 (Apple 로그인 성공 시)
        if !user.campus.rawValue.isEmpty {
            print("✅ 직접 인증 성공, 메인화면으로 이동")
            navigateToMainMenuWithCampus(user.campus)
        } else {
            print("❓ 캠퍼스 정보 없음, 캠퍼스 선택 화면으로 이동")
            navigateToCampusSelection()
        }
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
