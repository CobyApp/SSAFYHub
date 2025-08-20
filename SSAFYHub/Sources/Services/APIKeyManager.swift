import Foundation
import KeychainAccess

// MARK: - API Key Manager
class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()
    
    private let keychain = Keychain(service: "com.coby.ssafyhub.apikeys")
    
    private init() {}
    
    // MARK: - Supabase Keys
    var supabaseURL: String {
        get {
            // LocalConfig에서 직접 가져오기
            return LocalConfig.supabaseURL
        }
        set {
            // keychain에 저장 (선택사항)
            keychain["SUPABASE_URL"] = newValue
        }
    }
    
    var supabaseAnonKey: String {
        get {
            // LocalConfig에서 직접 가져오기
            return LocalConfig.supabaseAnonKey
        }
        set {
            // keychain에 저장 (선택사항)
            keychain["SUPABASE_ANON_KEY"] = newValue
        }
    }
    
    var supabaseServiceRoleKey: String {
        get {
            // keychain에서 읽기
            return keychain["SUPABASE_SERVICE_ROLE_KEY"] ?? ""
        }
        set {
            keychain["SUPABASE_SERVICE_ROLE_KEY"] = newValue
        }
    }
    
    // MARK: - OpenAI Keys
    var openAIAPIKey: String {
        get {
            // LocalConfig에서 직접 가져오기
            return LocalConfig.openAIAPIKey
        }
        set {
            // keychain에 저장 (선택사항)
            keychain["OPENAI_API_KEY"] = newValue
        }
    }
    
    var openAIBaseURL: String {
        get {
            // keychain에서 읽기, 없으면 기본값
            return keychain["OPENAI_BASE_URL"] ?? "https://api.openai.com/v1"
        }
        set {
            keychain["OPENAI_BASE_URL"] = newValue
        }
    }
    
    // MARK: - Validation
    var isSupabaseConfigured: Bool {
        return !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }
    
    var isOpenAIConfigured: Bool {
        return !openAIAPIKey.isEmpty
    }
    
    var isFullyConfigured: Bool {
        return isSupabaseConfigured && isOpenAIConfigured
    }
    
    // MARK: - Setup Methods
    func setupDefaultKeys() {
        // LocalConfig에서 항상 값을 가져오므로 별도 설정 불필요
        print("🔧 APIKeyManager: LocalConfig에서 API 키를 직접 사용합니다")
        printConfiguration()
    }
    
    // MARK: - Clear Keys
    func clearAllKeys() {
        // LocalConfig를 사용하므로 keychain만 정리
        try? keychain.remove("SUPABASE_URL")
        try? keychain.remove("SUPABASE_ANON_KEY")
        try? keychain.remove("SUPABASE_SERVICE_ROLE_KEY")
        try? keychain.remove("OPENAI_API_KEY")
        try? keychain.remove("OPENAI_BASE_URL")
        print("🔧 APIKeyManager: Keychain 정리 완료")
    }
    
    // MARK: - Debug Info
    func printConfiguration() {
        print("🔧 API Key Manager Configuration:")
        print("   🗄️ Supabase URL: \(supabaseURL)")
        print("   🔑 Supabase Anon Key: \(supabaseAnonKey.prefix(20))...")
        print("   🤖 OpenAI API Key: \(openAIAPIKey.prefix(20))...")
        print("   ✅ Supabase Configured: \(isSupabaseConfigured)")
        print("   ✅ OpenAI Configured: \(isOpenAIConfigured)")
        print("   ✅ Fully Configured: \(isFullyConfigured)")
        print("   📱 Source: LocalConfig.swift")
    }
}
