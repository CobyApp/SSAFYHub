import Foundation
import XCTest
import ComposableArchitecture
import SharedModels
@testable import SSAFYHub

final class SSAFYHubTests: XCTestCase {
    
    // MARK: - Auth Feature Tests
    func testAuthFeature_initialState() {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        }
        
        XCTAssertFalse(store.state.isAuthenticated)
        XCTAssertNil(store.state.currentUser)
        XCTAssertFalse(store.state.isLoading)
        XCTAssertNil(store.state.errorMessage)
    }
    
    func testAuthFeature_signInAsGuest() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        }
        
        await store.send(.signInAsGuest) {
            $0.isLoading = true
        }
        
        await store.receive(.userAuthenticated(AppUser(
            id: "guest_id",
            email: "guest@ssafyhub.com",
            campus: .daejeon,
            userType: .guest,
            createdAt: Date(),
            updatedAt: Date()
        ))) {
            $0.currentUser = AppUser(
                id: "guest_id",
                email: "guest@ssafyhub.com",
                campus: .daejeon,
                userType: .guest,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        await store.receive(.setLoading(false)) {
            $0.isLoading = false
        }
    }
    
    // MARK: - Menu Feature Tests
    func testMenuFeature_initialState() {
        let store = TestStore(initialState: MenuFeature.State()) {
            MenuFeature()
        }
        
        XCTAssertEqual(store.state.campus, .daejeon)
        XCTAssertNil(store.state.currentMenu)
        XCTAssertFalse(store.state.isLoading)
        XCTAssertNil(store.state.errorMessage)
    }
    
    func testMenuFeature_campusChanged() {
        let store = TestStore(initialState: MenuFeature.State()) {
            MenuFeature()
        }
        
        store.send(.campusChanged(.seoul)) {
            $0.campus = .seoul
        }
    }
    
    func testMenuFeature_dateChanged() {
        let store = TestStore(initialState: MenuFeature.State()) {
            MenuFeature()
        }
        
        let newDate = Date()
        store.send(.dateChanged(newDate)) {
            $0.currentDate = newDate
            $0.currentMenu = nil
            $0.errorMessage = nil
        }
    }
    
    // MARK: - Menu Editor Feature Tests
    func testMenuEditorFeature_initialState() {
        let store = TestStore(initialState: MenuEditorFeature.State()) {
            MenuEditorFeature()
        }
        
        XCTAssertEqual(store.state.campus, .daejeon)
        XCTAssertFalse(store.state.isSaving)
        XCTAssertNil(store.state.errorMessage)
        XCTAssertEqual(store.state.weeklyMenuItems.count, 5)
    }
    
    func testMenuEditorFeature_itemChanged() {
        let store = TestStore(initialState: MenuEditorFeature.State()) {
            MenuEditorFeature()
        }
        
        let firstItem = store.state.weeklyMenuItems[0].first!
        
        store.send(.itemChanged(dayIndex: 0, itemId: firstItem.id, text: "새로운 메뉴")) {
            if let index = $0.weeklyMenuItems[0].firstIndex(where: { $0.id == firstItem.id }) {
                $0.weeklyMenuItems[0][index].text = "새로운 메뉴"
            }
        }
    }
    
    func testMenuEditorFeature_addMenuItem() {
        let store = TestStore(initialState: MenuEditorFeature.State()) {
            MenuEditorFeature()
        }
        
        store.send(.addMenuItem(dayIndex: 0, mealType: .a)) {
            let newItem = MenuItem(text: "", mealType: .a)
            $0.weeklyMenuItems[0].append(newItem)
        }
    }
    
    func testMenuEditorFeature_removeMenuItem() {
        let store = TestStore(initialState: MenuEditorFeature.State()) {
            MenuEditorFeature()
        }
        
        let firstItem = store.state.weeklyMenuItems[0].first!
        
        store.send(.removeMenuItem(dayIndex: 0, itemId: firstItem.id)) {
            $0.weeklyMenuItems[0].removeAll { $0.id == firstItem.id }
        }
    }
    
    // MARK: - Shared Models Tests
    func testCampus_displayName() {
        XCTAssertEqual(Campus.seoul.displayName, "서울캠퍼스")
        XCTAssertEqual(Campus.daejeon.displayName, "대전캠퍼스")
        XCTAssertEqual(Campus.gwangju.displayName, "광주캠퍼스")
        XCTAssertEqual(Campus.gumi.displayName, "구미캠퍼스")
        XCTAssertEqual(Campus.busan.displayName, "부산캠퍼스")
    }
    
    func testCampus_isAvailable() {
        XCTAssertTrue(Campus.daejeon.isAvailable)
        XCTAssertFalse(Campus.seoul.isAvailable)
        XCTAssertFalse(Campus.gwangju.isAvailable)
        XCTAssertFalse(Campus.gumi.isAvailable)
        XCTAssertFalse(Campus.busan.isAvailable)
    }
    
    func testUserType_canEditMenus() {
        XCTAssertFalse(UserType.guest.canEditMenus)
        XCTAssertTrue(UserType.authenticated.canEditMenus)
    }
    
    func testUserType_canDeleteMenus() {
        XCTAssertFalse(UserType.guest.canDeleteMenus)
        XCTAssertTrue(UserType.authenticated.canDeleteMenus)
    }
    
    func testMealMenu_initialization() {
        let menu = MealMenu(
            id: "test_id",
            date: Date(),
            campus: .daejeon,
            itemsA: ["백미밥", "된장국"],
            itemsB: ["잡곡밥", "미역국"],
            updatedAt: Date(),
            updatedBy: "test_user"
        )
        
        XCTAssertEqual(menu.id, "test_id")
        XCTAssertEqual(menu.campus, .daejeon)
        XCTAssertEqual(menu.itemsA.count, 2)
        XCTAssertEqual(menu.itemsB.count, 2)
        XCTAssertEqual(menu.updatedBy, "test_user")
    }
    
    func testAppUser_initialization() {
        let user = AppUser(
            id: "user_id",
            email: "test@test.com",
            campus: .daejeon,
            userType: .authenticated,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertEqual(user.id, "user_id")
        XCTAssertEqual(user.email, "test@test.com")
        XCTAssertEqual(user.campus, .daejeon)
        XCTAssertEqual(user.userType, .authenticated)
        XCTAssertTrue(user.isAuthenticated)
        XCTAssertFalse(user.isGuest)
    }
    
    // MARK: - Error Handling Tests
    func testAppError_networkError() {
        let networkError = AppError.network(.noConnection)
        XCTAssertEqual(networkError.errorDescription, "인터넷 연결을 확인해주세요.")
        XCTAssertTrue(networkError.isRecoverable)
        XCTAssertEqual(networkError.severity, .medium)
    }
    
    func testAppError_aiError() {
        let aiError = AppError.ai(.apiRequestFailed)
        XCTAssertEqual(aiError.errorDescription, "AI 서비스 요청에 실패했습니다. 다시 시도해주세요.")
        XCTAssertTrue(aiError.isRecoverable)
        XCTAssertEqual(aiError.severity, .high)
    }
    
    func testAppError_authError() {
        let authError = AppError.authentication(.sessionExpired)
        XCTAssertEqual(authError.errorDescription, "로그인이 만료되었습니다. 다시 로그인해주세요.")
        XCTAssertTrue(authError.isRecoverable)
        XCTAssertEqual(authError.severity, .medium)
    }
    
    // MARK: - Cache Manager Tests
    func testCacheManager_storeAndRetrieve() async {
        let cacheManager = MockCacheManager()
        
        let testData = TestUtilities.createMockMenu(date: Date())
        
        // 저장
        await cacheManager.store(testData, forKey: "test_key")
        
        // 조회
        let retrievedData = await cacheManager.retrieve(MealMenu.self, forKey: "test_key")
        
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData?.id, testData.id)
        XCTAssertEqual(retrievedData?.campus, testData.campus)
    }
    
    func testCacheManager_remove() async {
        let cacheManager = MockCacheManager()
        
        let testData = TestUtilities.createMockMenu(date: Date())
        
        // 저장
        await cacheManager.store(testData, forKey: "test_key")
        
        // 제거
        await cacheManager.remove(forKey: "test_key")
        
        // 조회 (nil이어야 함)
        let retrievedData = await cacheManager.retrieve(MealMenu.self, forKey: "test_key")
        
        XCTAssertNil(retrievedData)
    }
    
    // MARK: - Performance Tests
    func testPerformance_largeMenuData() {
        measure {
            let largeItems = Array(repeating: "메뉴 아이템", count: 100)
            let menu = MealMenu(
                id: UUID().uuidString,
                date: Date(),
                campus: .daejeon,
                itemsA: largeItems,
                itemsB: largeItems,
                updatedAt: Date(),
                updatedBy: "test_user"
            )
            
            XCTAssertEqual(menu.itemsA.count, 100)
            XCTAssertEqual(menu.itemsB.count, 100)
        }
    }
    
    // MARK: - Integration Tests
    func testIntegration_authToMenuFlow() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        
        // 1. 게스트 로그인
        await store.send(.auth(.signInAsGuest)) {
            $0.auth.isLoading = true
        }
        
        // 2. 메뉴 로드
        await store.send(.menu(.loadMenu)) {
            $0.menu.isLoading = true
        }
    }
}