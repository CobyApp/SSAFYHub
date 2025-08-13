import Foundation
import WidgetKit

class WidgetDataService {
    static let shared = WidgetDataService()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.coby.ssafyhub")
    
    private init() {}
    
    // 위젯에 현재 메뉴 데이터 공유
    func shareMenuToWidget(_ menu: Menu) {
        do {
            let menuData = try JSONEncoder().encode(menu)
            userDefaults?.set(menuData, forKey: "currentMenu")
            userDefaults?.synchronize()
            
            // 위젯 업데이트 강제 요청
            WidgetCenter.shared.reloadAllTimelines()
            
            print("📱 위젯에 메뉴 데이터 공유 완료: \(menu.date)")
            print("🔄 위젯 업데이트 요청 완료")
        } catch {
            print("❌ 위젯 데이터 공유 실패: \(error)")
        }
    }
    
    // 위젯에서 메뉴 데이터 가져오기
    func getMenuFromWidget() -> Menu? {
        guard let menuData = userDefaults?.data(forKey: "currentMenu") else {
            return nil
        }
        
        do {
            let menu = try JSONDecoder().decode(Menu.self, from: menuData)
            return menu
        } catch {
            print("❌ 위젯에서 메뉴 데이터 가져오기 실패: \(error)")
            return nil
        }
    }
    
    // 위젯 데이터 초기화
    func clearWidgetData() {
        userDefaults?.removeObject(forKey: "currentMenu")
        userDefaults?.synchronize()
        
        // 위젯 업데이트 강제 요청
        WidgetCenter.shared.reloadAllTimelines()
        
        print("📱 위젯 데이터 초기화 완료")
        print("🔄 위젯 업데이트 요청 완료")
    }
}
