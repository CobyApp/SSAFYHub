import Foundation
import Supabase

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        // TODO: 실제 Supabase 프로젝트 URL과 anon key로 교체
        let supabaseURL = "YOUR_SUPABASE_URL"
        let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }
    
    // MARK: - Authentication
    func signInWithApple() async throws -> User {
        // Apple Sign In 구현
        // Supabase Auth를 통해 Apple 인증
        return try await withCheckedThrowingContinuation { continuation in
            // TODO: Apple Sign In 구현
            // 임시로 더미 사용자 반환
            let dummyUser = User(
                id: UUID().uuidString,
                email: "user@example.com",
                campus: .seoul,
                createdAt: Date(),
                updatedAt: Date()
            )
            continuation.resume(returning: dummyUser)
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func deleteAccount() async throws {
        // TODO: 계정 삭제 구현
    }
    
    // MARK: - User Management
    func updateUserCampus(_ campus: Campus) async throws {
        // TODO: 사용자 캠퍼스 업데이트 구현
    }
    
    // MARK: - Menu Management
    func fetchMenu(for date: Date, campus: Campus) async throws -> Menu? {
        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        
        let response = try await client
            .database
            .from("menus")
            .select()
            .eq("date", value: dateString)
            .eq("campus_id", value: campus.rawValue)
            .order("revision", ascending: false)
            .limit(1)
            .execute()
        
        // 응답을 JSON으로 파싱
        let data = response.data
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstResult = jsonArray.first else {
            return nil
        }
        
        // JSON 데이터를 Menu 객체로 변환
        let itemsA = (firstResult["items_a"] as? [String]) ?? []
        let itemsB = (firstResult["items_b"] as? [String]) ?? []
        let revision = (firstResult["revision"] as? Int) ?? 1
        let id = firstResult["id"] as? String ?? UUID().uuidString
        
        let menu = Menu(
            id: id,
            date: date,
            campus: campus,
            itemsA: itemsA,
            itemsB: itemsB,
            updatedAt: Date(),
            updatedBy: firstResult["updated_by"] as? String ?? "",
            revision: revision
        )
        
        return menu
    }
    
    func saveMenu(_ menuInput: MenuInput) async throws -> Menu {
        let response = try await client
            .database
            .from("menus")
            .insert(menuInput)
            .select()
            .single()
            .execute()
        
        // 응답을 JSON으로 파싱
        let data = response.data
        guard let jsonResult = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "SupabaseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        // JSON 데이터를 Menu 객체로 변환
        let itemsA = (jsonResult["items_a"] as? [String]) ?? []
        let itemsB = (jsonResult["items_b"] as? [String]) ?? []
        let revision = (jsonResult["revision"] as? Int) ?? 1
        let id = jsonResult["id"] as? String ?? UUID().uuidString
        
        let menu = Menu(
            id: id,
            date: menuInput.date,
            campus: menuInput.campus,
            itemsA: itemsA,
            itemsB: itemsB,
            updatedAt: Date(),
            updatedBy: jsonResult["updated_by"] as? String ?? "",
            revision: revision
        )
        
        return menu
    }
    
    func updateMenu(_ menu: Menu, with menuInput: MenuInput) async throws -> Menu {
        // 업데이트할 데이터를 JSON으로 변환
        let updateData: [String: Any] = [
            "items_a": menuInput.itemsA,
            "items_b": menuInput.itemsB,
            "updated_by": "current_user_id", // TODO: 실제 사용자 ID로 교체
            "revision": menu.revision + 1
        ]
        
        // Dictionary를 JSON Data로 변환
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        
        let response = try await client
            .database
            .from("menus")
            .update(jsonData)
            .eq("id", value: menu.id)
            .select()
            .single()
            .execute()
        
        // 응답을 JSON으로 파싱
        let data = response.data
        guard let jsonResult = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "SupabaseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        // JSON 데이터를 Menu 객체로 변환
        let itemsA = (jsonResult["items_a"] as? [String]) ?? []
        let itemsB = (jsonResult["items_b"] as? [String]) ?? []
        let revision = (jsonResult["revision"] as? Int) ?? 1
        
        let updatedMenu = Menu(
            id: menu.id,
            date: menuInput.date,
            campus: menuInput.campus,
            itemsA: itemsA,
            itemsB: itemsB,
            updatedAt: Date(),
            updatedBy: jsonResult["updated_by"] as? String ?? "",
            revision: revision
        )
        
        return updatedMenu
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
