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
        let dateString = dateFormatter.string(from: date)
        
        let response = try await client.database
            .from("menus")
            .select()
            .eq("date", value: dateString)
            .eq("campus_id", value: campus.rawValue)
            .single()
            .execute()
        
        let data = response.data
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let menu = try decoder.decode(Menu.self, from: data)
        return menu
    }
    
    func saveMenu(menuInput: MenuInput, updatedBy: String?) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: menuInput.date)
        
        var dataToSave: [String: String] = [
            "date": dateString,
            "campus_id": menuInput.campus.rawValue,
            "items_a": menuInput.itemsA.joined(separator: ","),
            "items_b": menuInput.itemsB.joined(separator: ",")
        ]
        
        if let updatedBy = updatedBy {
            dataToSave["updated_by"] = updatedBy
        }
        
        let _ = try await client.database
            .from("menus")
            .upsert(dataToSave, onConflict: "date,campus_id")
            .execute()
    }
}
