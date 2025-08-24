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
            // 1. 환경 변수에서 읽기
            if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envURL.isEmpty {
                return envURL
            }
            // 2. keychain에서 읽기
            if let keychainURL = keychain["SUPABASE_URL"], !keychainURL.isEmpty {
                return keychainURL
            }
            // 3. 기본값 반환 (개발용)
            return ""
        }
        set {
            keychain["SUPABASE_URL"] = newValue
        }
    }
    
    var supabaseAnonKey: String {
        get {
            // 1. 환경 변수에서 읽기
            if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !envKey.isEmpty {
                return envKey
            }
            // 2. keychain에서 읽기
            if let keychainKey = keychain["SUPABASE_ANON_KEY"], !keychainKey.isEmpty {
                return keychainKey
            }
            // 3. 기본값 반환 (개발용)
            return ""
        }
        set {
            keychain["SUPABASE_ANON_KEY"] = newValue
        }
    }
    
    var supabaseServiceRoleKey: String {
        get {
            // 1. 환경 변수에서 읽기
            if let envKey = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"], !envKey.isEmpty {
                return envKey
            }
            // 2. keychain에서 읽기
            return keychain["SUPABASE_SERVICE_ROLE_KEY"] ?? ""
        }
        set {
            keychain["SUPABASE_SERVICE_ROLE_KEY"] = newValue
        }
    }
    
    // MARK: - OpenAI Keys
    var openAIAPIKey: String {
        get {
            // 1. 환경 변수에서 읽기
            if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
                return envKey
            }
            // 2. keychain에서 읽기
            if let keychainKey = keychain["OPENAI_API_KEY"], !keychainKey.isEmpty {
                return keychainKey
            }
            // 3. 기본값 반환 (개발용)
            return ""
        }
        set {
            keychain["OPENAI_API_KEY"] = newValue
        }
    }
    
    var openAIBaseURL: String {
        get {
            // 1. 환경 변수에서 읽기
            if let envURL = ProcessInfo.processInfo.environment["OPENAI_BASE_URL"], !envURL.isEmpty {
                return envURL
            }
            // 2. keychain에서 읽기
            if let keychainURL = keychain["OPENAI_BASE_URL"], !keychainURL.isEmpty {
                return keychainURL
            }
            // 3. 기본값 반환
            return "https://api.openai.com/v1"
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
        print("🔧 APIKeyManager: 환경 변수 또는 keychain에서 API 키를 읽어옵니다")
        printConfiguration()
    }
    
    // MARK: - Clear Keys
    func clearAllKeys() {
        try? keychain.remove("SUPABASE_URL")
        try? keychain.remove("SUPABASE_ANON_KEY")
        try? keychain.remove("SUPABASE_SERVICE_ROLE_KEY")
        try? keychain.remove("OPENAI_API_KEY")
        try? keychain.remove("OPENAI_BASE_URL")
        print("🔧 APIKeyManager: Keychain 정리 완료")
    }
    
    // MARK: - Debug Info
    func printConfiguration() {
        let source = getConfigurationSource()
        print("🔧 API Key Manager Configuration:")
        print("   🗄️ Supabase URL: \(supabaseURL)")
        print("   🔑 Supabase Anon Key: \(supabaseAnonKey.prefix(20))...")
        print("   🤖 OpenAI API Key: \(openAIAPIKey.prefix(20))...")
        print("   ✅ Supabase Configured: \(isSupabaseConfigured)")
        print("   ✅ OpenAI Configured: \(isOpenAIConfigured)")
        print("   ✅ Fully Configured: \(isFullyConfigured)")
        print("   📱 Source: \(source)")
    }
    
    private func getConfigurationSource() -> String {
        if ProcessInfo.processInfo.environment["SUPABASE_URL"] != nil || 
           ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil {
            return "Environment Variables"
        } else if keychain["SUPABASE_URL"] != nil || keychain["OPENAI_API_KEY"] != nil {
            return "Keychain"
        } else {
            return "Default Values (Development)"
        }
    }
}
