import Foundation
import Supabase
import AuthenticationServices

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = "https://gijhwyoagvkmijxzpelr.supabase.co"
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdpamh3eW9hZ3ZrbWlqeHpwZWxyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5NzU3MzEsImV4cCI6MjA3MDU1MTczMX0.ggxD_gO-RrC_lIEkvhprTKjFHCcDmHfrOk8mz8rxDFA"
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }
    
    // MARK: - Apple Sign In
    func authenticateWithApple(identityToken: String) async throws -> User {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: identityToken,
                nonce: ""
            )
        )
        
        let user = session.user
        let userId = user.id.uuidString
        let userEmail = user.email ?? "unknown@apple.com"
        let userCampus: Campus = .seoul
        
        let existingUser = try? await getCurrentUser()
        
        if let existingUser = existingUser {
            return existingUser
        } else {
            let newUser = User(
                id: userId,
                email: userEmail,
                campus: userCampus,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await upsertUser(newUser)
            return newUser
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - Session Management
    func getCurrentSession() async throws -> Session {
        do {
            let session = try await client.auth.session
            print("🔍 SupabaseService: 세션 확인됨 - 사용자: \(session.user.email ?? "unknown")")
            return session
        } catch {
            print("❌ SupabaseService: 세션 가져오기 실패: \(error)")
            throw error
        }
    }
    
    func refreshSessionIfNeeded() async throws {
        do {
            let session = try await client.auth.session
            print("🔍 SupabaseService: 세션 상태 확인 - 사용자: \(session.user.email ?? "unknown")")
            
            // 세션 만료 시간 확인 (accessToken의 만료 시간 사용)
            let accessToken = session.accessToken
            if !accessToken.isEmpty {
                // JWT 토큰의 만료 시간을 디코딩하여 확인
                let tokenParts = accessToken.components(separatedBy: ".")
                if tokenParts.count >= 2 {
                    // Base64 디코딩 (패딩 추가)
                    var base64 = tokenParts[1]
                    while base64.count % 4 != 0 {
                        base64 += "="
                    }
                    
                    if let data = Data(base64Encoded: base64),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let exp = json["exp"] as? TimeInterval {
                        
                        let expirationDate = Date(timeIntervalSince1970: exp)
                        let oneHourFromNow = Date().addingTimeInterval(3600)
                        
                        print("🔍 SupabaseService: 토큰 만료 시간: \(expirationDate)")
                        
                        if expirationDate < oneHourFromNow {
                            print("🔄 SupabaseService: 세션 갱신 시작")
                            try await client.auth.refreshSession()
                            print("✅ SupabaseService: 세션 갱신 완료")
                        } else {
                            print("✅ SupabaseService: 세션이 아직 유효함")
                        }
                    } else {
                        print("⚠️ SupabaseService: 토큰 만료 시간을 파싱할 수 없음")
                    }
                }
            } else {
                print("⚠️ SupabaseService: accessToken이 비어있음")
            }
        } catch {
            // 세션이 없는 경우는 정상적인 상황이므로 에러를 던지지 않음
            print("ℹ️ SupabaseService: 세션이 없음 (로그인 필요)")
            // 에러를 던지지 않고 정상적으로 처리
        }
    }
    
    func getCurrentUser() async throws -> User? {
        let session = try await client.auth.session
        let userId = session.user.id.uuidString
        
        let response = try await client.database
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
        
        let data = response.data
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let user = try decoder.decode(User.self, from: data)
        return user
    }
    
    func updateUserCampus(userId: String, campus: Campus) async throws {
        let updateData: [String: String] = ["campus_id": campus.rawValue]
        
        let _ = try await client.database
            .from("users")
            .update(updateData)
            .eq("id", value: userId)
            .execute()
    }
    
    func upsertUser(_ user: User) async throws {
        let userData: [String: String] = [
            "id": user.id,
            "email": user.email,
            "campus_id": user.campus.rawValue,
            "created_at": ISO8601DateFormatter().string(from: user.createdAt),
            "updated_at": ISO8601DateFormatter().string(from: user.updatedAt)
        ]
        
        try await client
            .database
            .from("users")
            .upsert(userData, onConflict: "id")
            .execute()
    }
    
    func fetchMenu(date: Date, campus: Campus) async throws -> Menu? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        print("🔍 SupabaseService: 메뉴 조회 - 날짜: \(dateString), 캠퍼스: \(campus.rawValue)")
        
        // 명시적으로 모든 컬럼 선택
        let response = try await client.database
            .from("menus")
            .select("id, date, campus_id, items_a, items_b, updated_at, updated_by")
            .eq("date", value: dateString)
            .eq("campus_id", value: campus.rawValue)
            .single()
            .execute()
        
        let data = response.data
        print("🔍 SupabaseService: 응답 데이터 크기: \(data.count) bytes")
        
        // 응답 데이터 내용 확인
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 SupabaseService: 응답 JSON 데이터: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        // keyDecodingStrategy 제거 - CodingKeys와 정확히 매치
        // decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let menu = try decoder.decode(Menu.self, from: data)
        print("✅ SupabaseService: 메뉴 조회 성공 - ID: \(menu.id)")
        return menu
    }
    
    func saveMenu(menuInput: MenuInput, updatedBy: String?) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: menuInput.date)
        
        print("💾 SupabaseService: 메뉴 저장 시작")
        print("📅 날짜: \(dateString)")
        print("🏫 캠퍼스: \(menuInput.campus.rawValue)")
        print("🍽️ A타입: \(menuInput.itemsA)")
        print("🍽️ B타입: \(menuInput.itemsB)")
        
        // MenuInput을 직접 사용하여 Encodable 준수
        let menuData = menuInput
        
        // MenuInput 데이터를 JSON으로 변환하여 로깅
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let jsonData = try encoder.encode(menuData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🔍 MenuInput JSON 데이터: \(jsonString)")
            }
        } catch {
            print("⚠️ MenuInput JSON 변환 실패: \(error)")
        }
        
        // updatedBy가 있으면 추가
        if let updatedBy = updatedBy {
            print("👤 수정자: \(updatedBy)")
            
            // MenuInput에 updatedBy 필드가 없으므로 별도로 처리
            let dataToSave: [String: String] = [
                "date": dateString,
                "campus_id": menuInput.campus.rawValue,
                "updated_by": updatedBy
            ]
            
            print("💾 Supabase에 저장할 데이터: \(dataToSave)")
            
            // 먼저 기본 메뉴 데이터 저장 (items_a, items_b 포함)
            let _ = try await client.database
                .from("menus")
                .upsert(menuData, onConflict: "date,campus_id")
                .execute()
            
            print("✅ 기본 메뉴 데이터 저장 완료")
            
            // updated_by 필드 업데이트
            let _ = try await client.database
                .from("menus")
                .update(dataToSave)
                .eq("date", value: dateString)
                .eq("campus_id", value: menuInput.campus.rawValue)
                .execute()
            
            print("✅ updated_by 필드 업데이트 완료")
        } else {
            print("💾 Supabase에 저장할 데이터: \(menuData)")
            
            let _ = try await client.database
                .from("menus")
                .upsert(menuData, onConflict: "date,campus_id")
                .execute()
            
            print("✅ 메뉴 데이터 저장 완료")
        }
        
        print("✅ SupabaseService: 메뉴 저장 완료")
    }
    
    // MARK: - Weekly Menu Saving
    func saveWeeklyMenu(weeklyInput: WeeklyMenuInput, updatedBy: String?) async throws {
        print("📅 주간 메뉴 저장 시작")
        print("🏫 캠퍼스: \(weeklyInput.campus.displayName)")
        print("📅 시작일: \(weeklyInput.startDate)")
        print("🍽️ 총 메뉴 수: \(weeklyInput.weeklyMenus.count)일")
        
        // 각 일자별로 메뉴 저장
        for (index, dailyMenu) in weeklyInput.weeklyMenus.enumerated() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: dailyMenu.date)
            
            print("📅 \(index + 1)일차 메뉴 저장: \(dateString)")
            print("🍽️ A타입: \(dailyMenu.itemsA)")
            print("🍽️ B타입: \(dailyMenu.itemsB)")
            
            let menuInput = MenuInput(
                date: dailyMenu.date,
                campus: weeklyInput.campus,
                itemsA: dailyMenu.itemsA,
                itemsB: dailyMenu.itemsB
            )
            
            try await saveMenu(menuInput: menuInput, updatedBy: updatedBy)
        }
        
        print("✅ 주간 메뉴 저장 완료")
    }
}
