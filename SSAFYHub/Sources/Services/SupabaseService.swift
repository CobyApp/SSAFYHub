import Foundation
import Supabase
import AuthenticationServices
import KeychainAccess

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        // APIKeyManager에서 Supabase 설정 가져오기
        let apiKeyManager = APIKeyManager.shared
        
        // 기본 키 설정 (첫 실행 시)
        apiKeyManager.setupDefaultKeys()
        
        let supabaseURL = apiKeyManager.supabaseURL
        let supabaseAnonKey = apiKeyManager.supabaseAnonKey
        
        // 설정 유효성 검사
        guard apiKeyManager.isSupabaseConfigured else {
            fatalError("❌ SupabaseService: Supabase 설정이 유효하지 않습니다. APIKeyManager를 확인해주세요.")
        }
        
        // Supabase 2.0.0+ 버전에서는 기본적으로 세션 지속 저장이 활성화됨
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
        
        print("🔧 SupabaseService: 클라이언트 초기화 완료 - 세션 지속 저장 기본 활성화")
        print("🔧 SupabaseService: URL: \(supabaseURL)")
        print("🔧 SupabaseService: Anon Key: \(supabaseAnonKey.prefix(20))...")
        
        // API Key Manager 설정 정보 출력
        apiKeyManager.printConfiguration()
    }
    
    // MARK: - Apple Sign In
    func authenticateWithApple(identityToken: String) async throws -> User {
        print("🍎 SupabaseService: Apple 로그인 시작")
        
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
        
        // 수동 세션 저장
        await saveSessionManually(session)
        
        let existingUser = try? await getCurrentUser()
        
        if let existingUser = existingUser {
            // 기존 사용자 정보 업데이트 및 세션 저장
            await saveUserSession(existingUser)
            print("🍎 SupabaseService: 기존 사용자 Apple 로그인 성공 - \(existingUser.email)")
            print("🏫 기존 사용자 캠퍼스: \(existingUser.campus.displayName)")
            return existingUser
        } else {
            // 새 사용자는 기본적으로 대전캠퍼스로 설정
            let userCampus: Campus = .daejeon
            print("🏫 새 사용자 기본 캠퍼스 설정: \(userCampus.displayName)")
            
            let newUser = User(
                id: userId,
                email: userEmail,
                campus: userCampus,
                userType: .authenticated,  // Apple 로그인 사용자는 인증된 사용자
                createdAt: Date(),
                updatedAt: Date()
            )
            try await upsertUser(newUser)
            
            // 새 사용자 세션 저장
            await saveUserSession(newUser)
            print("🍎 SupabaseService: 새 사용자 Apple 로그인 성공 - \(newUser.email)")
            print("🏫 새 사용자 캠퍼스: \(newUser.campus.displayName)")
            return newUser
        }
    }
    
    func signOut() async throws {
        print("🚪 SupabaseService: 로그아웃 시작")
        
        // Supabase 세션 로그아웃
        try await client.auth.signOut()
        
        // 저장된 사용자 세션 정리
        UserDefaults.standard.removeObject(forKey: "saved.user.session")
        
        let keychain = Keychain(service: "com.coby.ssafyhub.user")
        try? keychain.remove("user.session")
        
        // 수동 저장된 Supabase 세션도 정리
        UserDefaults.standard.removeObject(forKey: "manual.supabase.session")
        
        let sessionKeychain = Keychain(service: "com.coby.ssafyhub.session")
        try? sessionKeychain.remove("manual.session")
        
        print("✅ SupabaseService: 로그아웃 완료 - 모든 저장된 세션 정리됨")
    }
    
    // MARK: - Session Management
    func getCurrentSession() async throws -> Session {
        let session = try await client.auth.session
        print("🔍 SupabaseService: 현재 세션 확인 - 사용자: \(session.user.email ?? "unknown")")
        print("🔍 SupabaseService: 세션 토큰 길이: \(session.accessToken.count) characters")
        
        // 세션 저장 상태 확인
        await checkSessionPersistence()
        
        return session
    }
    
    // 세션 지속 저장 상태 확인
    private func checkSessionPersistence() async {
        // UserDefaults에서 세션 정보 확인
        let userDefaults = UserDefaults.standard
        let sessionKey = "supabase.auth.token"
        
        if let sessionData = userDefaults.data(forKey: sessionKey) {
            print("💾 SupabaseService: UserDefaults에 세션 데이터 발견 - 크기: \(sessionData.count) bytes")
            
            // 세션 데이터 내용 확인 (디버깅용)
            if let jsonString = String(data: sessionData, encoding: .utf8) {
                print("🔍 SupabaseService: 저장된 세션 데이터: \(jsonString)")
            }
        } else {
            print("⚠️ SupabaseService: UserDefaults에 세션 데이터 없음")
        }
        
        // 키체인에서도 확인
        let keychain = Keychain(service: "com.coby.ssafyhub.session")
        if let keychainData = try? keychain.getData("supabase.auth.token") {
            print("🔑 SupabaseService: 키체인에 세션 데이터 발견 - 크기: \(keychainData.count) bytes")
        } else {
            print("⚠️ SupabaseService: 키체인에 세션 데이터 없음")
        }
    }
    
    func refreshSessionIfNeeded() async throws {
        do {
            let session = try await client.auth.session
            print("�� SupabaseService: 세션 상태 확인 - 사용자: \(session.user.email ?? "unknown")")
            
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
    
    // MARK: - Simple Session Persistence
    func saveUserSession(_ user: User) async {
        do {
            let encoder = JSONEncoder()
            let userData = try encoder.encode(user)
            
            // UserDefaults에 사용자 정보 저장
            UserDefaults.standard.set(userData, forKey: "saved.user.session")
            print("💾 SupabaseService: 사용자 세션 저장 완료 - \(user.email)")
            
            // 키체인에도 저장
            let keychain = Keychain(service: "com.coby.ssafyhub.user")
            try keychain.set(userData, key: "user.session")
            print("🔑 SupabaseService: 키체인에 사용자 세션 저장 완료")
            
        } catch {
            print("❌ SupabaseService: 사용자 세션 저장 실패: \(error)")
        }
    }
    
    func restoreUserSession() async -> User? {
        do {
            // 먼저 키체인에서 시도
            let keychain = Keychain(service: "com.coby.ssafyhub.user")
            if let userData = try? keychain.getData("user.session") {
                let decoder = JSONDecoder()
                let user = try decoder.decode(User.self, from: userData)
                print("🔑 SupabaseService: 키체인에서 사용자 세션 복구 성공 - \(user.email)")
                return user
            }
            
            // UserDefaults에서 시도
            if let userData = UserDefaults.standard.data(forKey: "saved.user.session") {
                let decoder = JSONDecoder()
                let user = try decoder.decode(User.self, from: userData)
                print("💾 SupabaseService: UserDefaults에서 사용자 세션 복구 성공 - \(user.email)")
                return user
            }
            
            print("⚠️ SupabaseService: 저장된 사용자 세션 없음")
            return nil
            
        } catch {
            print("❌ SupabaseService: 사용자 세션 복구 실패: \(error)")
            return nil
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
    
    // MARK: - Guest Authentication
    func signInAsGuest(campus: Campus) async throws -> User {
        print("👤 SupabaseService: 게스트 로그인 시작 - 캠퍼스: \(campus.displayName)")
        
        // 게스트 사용자는 항상 대전캠퍼스로 강제 설정
        let forcedCampus: Campus = .daejeon
        print("⚠️ 게스트 사용자 캠퍼스를 대전으로 강제 설정: \(forcedCampus.displayName)")
        
        // 게스트 사용자 생성 (userType을 .guest로 명시)
        let guestUser = User(
            id: UUID().uuidString,
            email: "guest@ssafyhub.com",
            campus: forcedCampus,  // 대전캠퍼스로 강제 설정
            userType: .guest,  // 게스트 타입으로 명시
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // 사용자 데이터 저장
        try await upsertUser(guestUser)
        
        // 가상 세션 생성 (게스트용)
        let virtualSession = createVirtualSession(for: guestUser)
        
        // 수동 세션 저장
        await saveSessionManually(virtualSession)
        
        // 사용자 세션 저장
        await saveUserSession(guestUser)
        
        print("✅ SupabaseService: 게스트 로그인 완료")
        return guestUser
    }
    
    // 게스트용 가상 세션 생성
    private func createVirtualSession(for user: User) -> Session {
        // 게스트 사용자를 위한 가상 세션 생성
        // 실제 Supabase 세션이 아니므로 필요한 최소 정보만 포함
        
        // Auth.User 타입으로 변환 (필수 매개변수만 포함)
        let authUser = Auth.User(
            id: UUID(uuidString: user.id) ?? UUID(),
            appMetadata: [:],
            userMetadata: [:],
            aud: "authenticated",
            confirmationSentAt: nil,
            recoverySentAt: nil,
            emailChangeSentAt: nil,
            newEmail: nil,
            invitedAt: nil,
            actionLink: nil,
            email: user.email,
            phone: nil,
            createdAt: user.createdAt,
            confirmedAt: nil,
            emailConfirmedAt: nil,
            phoneConfirmedAt: nil,
            lastSignInAt: nil,
            role: nil,
            updatedAt: user.updatedAt,
            identities: [],
            factors: []
        )
        
        // 가상 세션 반환 (실제로는 사용되지 않음)
        return Session(
            providerToken: nil,
            providerRefreshToken: nil,
            accessToken: "guest_token_\(user.id)",
            tokenType: "bearer",
            expiresIn: 3600,
            refreshToken: "guest_refresh_\(user.id)",
            user: authUser
        )
    }
    
    // MARK: - Manual Session Persistence
    func saveSessionManually(_ session: Session) async {
        do {
            let encoder = JSONEncoder()
            let sessionData = try encoder.encode(session)
            
            // UserDefaults에 저장
            UserDefaults.standard.set(sessionData, forKey: "manual.supabase.session")
            print("💾 SupabaseService: 수동 세션 저장 완료 - UserDefaults")
            
            // 키체인에도 저장 (더 안전함)
            let keychain = Keychain(service: "com.coby.ssafyhub.session")
            try keychain.set(sessionData, key: "manual.session")
            print("🔑 SupabaseService: 수동 세션 저장 완료 - 키체인")
            
        } catch {
            print("❌ SupabaseService: 수동 세션 저장 실패: \(error)")
        }
    }
    
    func restoreSessionManually() async -> Session? {
        do {
            // 먼저 키체인에서 시도
            let keychain = Keychain(service: "com.coby.ssafyhub.session")
            if let sessionData = try? keychain.getData("manual.session") {
                let decoder = JSONDecoder()
                let session = try decoder.decode(Session.self, from: sessionData)
                print("🔑 SupabaseService: 키체인에서 수동 세션 복구 성공")
                return session
            }
            
            // UserDefaults에서 시도
            if let sessionData = UserDefaults.standard.data(forKey: "manual.supabase.session") {
                let decoder = JSONDecoder()
                let session = try decoder.decode(Session.self, from: sessionData)
                print("💾 SupabaseService: UserDefaults에서 수동 세션 복구 성공")
                return session
            }
            
            print("⚠️ SupabaseService: 수동 저장된 세션 없음")
            return nil
            
        } catch {
            print("❌ SupabaseService: 수동 세션 복구 실패: \(error)")
            return nil
        }
    }
    
    // MARK: - Account Management
    func deleteAccount() async throws {
        print("🗑️ SupabaseService: 회원탈퇴 시작")
        
        // 현재 사용자 정보 가져오기
        guard let currentUser = try? await client.auth.session.user else {
            print("❌ SupabaseService: 현재 사용자 정보를 찾을 수 없음")
            throw NSError(domain: "SupabaseService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "사용자 정보를 찾을 수 없습니다"])
        }
        
        let userId = currentUser.id.uuidString
        print("👤 삭제할 사용자 ID: \(userId)")
        
        do {
            // 1. 사용자가 작성한 메뉴 데이터 삭제
            print("🍽️ 사용자 메뉴 데이터 삭제 시작")
            try await client.database
                .from("menus")
                .delete()
                .eq("updated_by", value: currentUser.email ?? "unknown")
                .execute()
            print("✅ 사용자 메뉴 데이터 삭제 완료")
            
            // 2. 사용자 프로필 데이터 삭제
            print("👤 사용자 프로필 데이터 삭제 시작")
            try await client.database
                .from("users")
                .delete()
                .eq("id", value: userId)
                .execute()
            print("✅ 사용자 프로필 데이터 삭제 완료")
            
            // 3. 로컬 세션 및 데이터 정리
            print("🧹 로컬 데이터 정리 시작")
            
            // UserDefaults 정리
            UserDefaults.standard.removeObject(forKey: "manual.supabase.session")
            UserDefaults.standard.removeObject(forKey: "user.campus")
            UserDefaults.standard.removeObject(forKey: "user.preferences")
            
            // 키체인 정리
            let keychain = Keychain(service: "com.coby.ssafyhub.session")
            try? keychain.remove("manual.session")
            
            print("✅ 로컬 데이터 정리 완료")
            
            // 4. Supabase 인증 세션 정리 (로그아웃)
            print("🔐 Supabase 세션 정리 시작")
            try await client.auth.signOut()
            print("✅ Supabase 세션 정리 완료")
            
            print("✅ SupabaseService: 회원탈퇴 완료")
            
        } catch {
            print("❌ SupabaseService: 회원탈퇴 중 오류 발생: \(error)")
            
            // 부분적으로 삭제된 경우에도 로그아웃은 시도
            do {
                try await client.auth.signOut()
                print("⚠️ 부분 삭제 후 로그아웃 완료")
            } catch {
                print("❌ 로그아웃도 실패: \(error)")
            }
            
            // 구체적인 에러 메시지 제공
            let errorMessage: String
            if error.localizedDescription.contains("permission") {
                errorMessage = "권한이 부족하여 회원탈퇴를 완료할 수 없습니다. 관리자에게 문의하세요."
            } else if error.localizedDescription.contains("network") {
                errorMessage = "네트워크 오류로 회원탈퇴를 완료할 수 없습니다. 다시 시도해주세요."
            } else {
                errorMessage = "회원탈퇴 중 오류가 발생했습니다: \(error.localizedDescription)"
            }
            
            throw NSError(
                domain: "SupabaseService", 
                code: 1002, 
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }
    }
}
