import Foundation
import WidgetKit
import SharedModels

class WidgetDataService {
    static let shared = WidgetDataService()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.coby.ssafyhub")
    
    private init() {}
    
    // 위젯에 현재 메뉴 데이터 공유
    func shareMenuToWidget(_ menu: MealMenu) {
        // UserDefaults 객체 확인
        guard let userDefaults = userDefaults else {
            print("❌ 위젯 데이터 공유 실패: UserDefaults 객체가 nil")
            print("   - App Group 권한 문제일 수 있습니다")
            return
        }
        
        do {
            let menuData = try JSONEncoder().encode(menu)
            
            print("🔍 위젯 데이터 공유 시작:")
            print("   - 메뉴 ID: \(menu.id)")
            print("   - 메뉴 날짜: \(menu.date)")
            print("   - A타입 항목: \(menu.itemsA)")
            print("   - B타입 항목: \(menu.itemsB)")
            print("   - 인코딩된 데이터 크기: \(menuData.count) bytes")
            
            // 데이터 저장
            userDefaults.set(menuData, forKey: "currentMenu")
            userDefaults.set(Date(), forKey: "lastUpdateTime")
            userDefaults.synchronize()
            
            // 저장 확인
            if let savedData = userDefaults.data(forKey: "currentMenu") {
                print("📱 위젯에 메뉴 데이터 공유 완료: \(menu.date)")
                print("📊 저장된 데이터 크기: \(savedData.count) bytes")
                print("🕐 마지막 업데이트 시간: \(Date())")
                
                // 저장된 데이터 디코딩 테스트
                if let decodedMenu = try? JSONDecoder().decode(MealMenu.self, from: savedData) {
                    print("✅ 저장된 데이터 디코딩 테스트 성공:")
                    print("   - 디코딩된 메뉴 ID: \(decodedMenu.id)")
                    print("   - 디코딩된 메뉴 날짜: \(decodedMenu.date)")
                    print("   - 디코딩된 A타입: \(decodedMenu.itemsA.count)개")
                    print("   - 디코딩된 B타입: \(decodedMenu.itemsB.count)개")
                } else {
                    print("❌ 저장된 데이터 디코딩 테스트 실패")
                }
                
                // 저장된 모든 키 확인
                let allKeys = userDefaults.dictionaryRepresentation().keys
                print("   - 저장된 모든 키: \(Array(allKeys))")
                
            } else {
                print("❌ 위젯 데이터 저장 실패")
            }
            
                    // 위젯 업데이트 강제 요청
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 위젯 업데이트 요청 완료")
        
        // 위젯 상태 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkWidgetUpdateStatus()
        }
        
        // 잠시 후 다시 한번 업데이트 요청 (안전장치)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 위젯 업데이트 재요청 완료")
        }
        
        // 더 잠시 후 한번 더 업데이트 요청 (추가 안전장치)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 위젯 업데이트 3차 요청 완료")
        }
            
        } catch {
            print("❌ 위젯 데이터 공유 실패: \(error)")
        }
    }
    
    // 위젯에서 메뉴 데이터 가져오기
    func getMenuFromWidget() -> MealMenu? {
        guard let userDefaults = userDefaults else {
            print("❌ 위젯에서 메뉴 데이터 가져오기 실패: UserDefaults 객체가 nil")
            return nil
        }
        
        guard let menuData = userDefaults.data(forKey: "currentMenu") else {
            print("❌ 위젯에서 메뉴 데이터를 찾을 수 없음")
            print("   - 저장된 모든 키: \(Array(userDefaults.dictionaryRepresentation().keys))")
            return nil
        }
        
        do {
            let menu = try JSONDecoder().decode(MealMenu.self, from: menuData)
            print("✅ 위젯에서 메뉴 데이터 가져오기 성공: \(menu.date)")
            return menu
        } catch {
            print("❌ 위젯에서 메뉴 데이터 가져오기 실패: \(error)")
            return nil
        }
    }
    
    // 위젯 데이터 상태 확인
    func checkWidgetDataStatus() {
        print("🔍 위젯 데이터 상태 확인:")
        print("   - App Group: group.com.coby.ssafyhub")
        print("   - UserDefaults 객체: \(userDefaults?.description ?? "nil")")
        
        // App Group 권한 확인
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            print("   - 메인 앱 Bundle ID: \(bundleIdentifier)")
        }
        
        // Entitlements 확인
        if let entitlementsPath = Bundle.main.path(forResource: "SSAFYHub", ofType: "entitlements") {
            print("   - Entitlements 파일 경로: \(entitlementsPath)")
        } else {
            print("   - Entitlements 파일 경로: ❌ 찾을 수 없음")
        }
        
        // UserDefaults 객체가 nil인지 확인
        guard let userDefaults = userDefaults else {
            print("❌ UserDefaults 객체가 nil입니다")
            print("   - App Group 권한 문제일 수 있습니다")
            print("   - 프로비저닝 프로파일 확인 필요")
            print("   - Bundle ID 확인 필요")
            print("   - Entitlements 파일 확인 필요")
            return
        }
        
        // 저장된 모든 키와 값 확인
        let allKeys = userDefaults.dictionaryRepresentation()
        print("   - 저장된 모든 키: \(Array(allKeys.keys))")
        
        for (key, value) in allKeys {
            print("   - 키 '\(key)': \(value)")
        }
        
        if let menuData = userDefaults.data(forKey: "currentMenu") {
            print("📊 위젯 데이터 상태:")
            print("   - 데이터 크기: \(menuData.count) bytes")
            print("   - 데이터 존재: ✅")
            
            if let lastUpdate = userDefaults.object(forKey: "lastUpdateTime") as? Date {
                print("   - 마지막 업데이트: \(lastUpdate)")
            }
            
            // 저장된 데이터 디코딩 테스트
            do {
                let menu = try JSONDecoder().decode(MealMenu.self, from: menuData)
                print("✅ 저장된 데이터 디코딩 테스트 성공:")
                print("   - 메뉴 ID: \(menu.id)")
                print("   - 메뉴 날짜: \(menu.date)")
                print("   - A타입: \(menu.itemsA.count)개")
                print("   - B타입: \(menu.itemsB.count)개")
            } catch {
                print("❌ 저장된 데이터 디코딩 테스트 실패: \(error)")
                
                // 원본 데이터를 문자열로 출력하여 디버깅
                if let jsonString = String(data: menuData, encoding: .utf8) {
                    print("   - 원본 JSON 데이터: \(jsonString)")
                }
            }
        } else {
            print("📊 위젯 데이터 상태: ❌ 데이터 없음")
            print("   - 메인 앱에서 메뉴를 로드해야 합니다")
            print("   - 위젯 데이터 공유가 실행되지 않았습니다")
        }
        
        // 위젯 업데이트 상태 확인
        print("🔄 위젯 업데이트 상태:")
        print("   - WidgetCenter.shared.reloadAllTimelines() 호출 필요")
        
        // App Group 권한 테스트
        print("🔐 App Group 권한 테스트:")
        let testKey = "testKey_\(UUID().uuidString)"
        let testValue = "testValue_\(UUID().uuidString)"
        
        userDefaults.set(testValue, forKey: testKey)
        userDefaults.synchronize()
        
        if let retrievedValue = userDefaults.string(forKey: testKey) {
            print("   - App Group 쓰기/읽기 테스트: ✅ 성공")
            print("   - 테스트 키: \(testKey)")
            print("   - 테스트 값: \(testValue)")
            print("   - 읽은 값: \(retrievedValue)")
            
            // 테스트 데이터 정리
            userDefaults.removeObject(forKey: testKey)
            userDefaults.synchronize()
        } else {
            print("   - App Group 쓰기/읽기 테스트: ❌ 실패")
        }
    }
    
    // 위젯 업데이트 상태 확인
    func checkWidgetUpdateStatus() {
        print("🔄 위젯 업데이트 상태 확인:")
        
        // WidgetCenter 상태 확인
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.getCurrentConfigurations { result in
                switch result {
                case .success(let configurations):
                    print("   - 위젯 구성: \(configurations.count)개")
                    for config in configurations {
                        print("     - 위젯 ID: \(config.kind)")
                        print("     - 위젯 패밀리: \(config.family)")
                    }
                case .failure(let error):
                    print("   - 위젯 구성 확인 실패: \(error)")
                }
            }
        } else {
            print("   - 위젯 구성 확인: iOS 14.0 이상 필요")
        }
        
        // 위젯 업데이트 요청 상태 확인
        print("   - 위젯 업데이트 요청 완료")
        print("   - 위젯 업데이트 대기 중...")
    }
    
    // 위젯 데이터 초기화
    func clearWidgetData() {
        guard let userDefaults = userDefaults else {
            print("❌ 위젯 데이터 초기화 실패: UserDefaults 객체가 nil")
            return
        }
        
        userDefaults.removeObject(forKey: "currentMenu")
        userDefaults.removeObject(forKey: "lastUpdateTime")
        userDefaults.synchronize()
        
        // 위젯 업데이트 강제 요청
        WidgetCenter.shared.reloadAllTimelines()
        
        print("📱 위젯 데이터 초기화 완료")
        print("🔄 위젯 업데이트 요청 완료")
        
        // 초기화 후 상태 확인
        checkWidgetDataStatus()
    }
    
    // 테스트용 더미 데이터 생성 및 공유
    func shareTestDataToWidget() {
        let testMenu = MealMenu(
            id: UUID().uuidString,
            date: Date(),
            campus: .seoul,
            itemsA: ["테스트 A메뉴 1", "테스트 A메뉴 2", "테스트 A메뉴 3"],
            itemsB: ["테스트 B메뉴 1", "테스트 B메뉴 2"],
            updatedAt: Date(),
            updatedBy: "테스트"
        )
        
        print("🧪 테스트 데이터 생성 및 공유 시작")
        print("   - 테스트 메뉴 ID: \(testMenu.id)")
        print("   - 테스트 메뉴 날짜: \(testMenu.date)")
        print("   - 테스트 A타입: \(testMenu.itemsA)")
        print("   - 테스트 B타입: \(testMenu.itemsB)")
        
        shareMenuToWidget(testMenu)
        
        // 테스트 데이터 공유 후 상태 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkWidgetDataStatus()
        }
        
        // 위젯 업데이트 강제 요청
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WidgetCenter.shared.reloadAllTimelines()
            print("🧪 테스트 데이터 위젯 업데이트 요청 완료")
        }
    }
}
