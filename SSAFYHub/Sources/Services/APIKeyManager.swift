import Foundation
import KeychainAccess

// MARK: - API Key Manager
class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()
    
    private let keychain = Keychain(service: "com.coby.ssafyhub.apikeys")
    
    // MARK: - Entitlements Keys
    private enum EntitlementsKey: String, CaseIterable {
        case supabaseURL = "SUPABASE_URL"
        case supabaseAnonKey = "SUPABASE_ANON_KEY"
        case supabaseServiceRoleKey = "SUPABASE_SERVICE_ROLE_KEY"
        case openAIAPIKey = "OPENAI_API_KEY"
        case openAIBaseURL = "OPENAI_BASE_URL"
    }
    
    private init() {}
    
    // MARK: - Supabase Keys
    var supabaseURL: String {
        get {
            // 먼저 entitlements에서 읽기 시도
            if let url = Bundle.main.infoDictionary?[EntitlementsKey.supabaseURL.rawValue] as? String {
                return url
            }
            // 없으면 keychain에서 읽기
            return keychain[EntitlementsKey.supabaseURL.rawValue] ?? ""
        }
        set {
            // keychain에 저장 (entitlements는 읽기 전용)
            keychain[EntitlementsKey.supabaseURL.rawValue] = newValue
        }
    }
    
    var supabaseAnonKey: String {
        get {
            // 먼저 entitlements에서 읽기 시도
            if let key = Bundle.main.infoDictionary?[EntitlementsKey.supabaseAnonKey.rawValue] as? String {
                return key
            }
            // 없으면 keychain에서 읽기
            return keychain[EntitlementsKey.supabaseAnonKey.rawValue] ?? ""
        }
        set {
            // keychain에 저장 (entitlements는 읽기 전용)
            keychain[EntitlementsKey.supabaseAnonKey.rawValue] = newValue
        }
    }
    
    var supabaseServiceRoleKey: String {
        get {
            // 먼저 entitlements에서 읽기 시도
            if let key = Bundle.main.infoDictionary?[EntitlementsKey.supabaseServiceRoleKey.rawValue] as? String {
                return key
            }
            // 없으면 keychain에서 읽기
            return keychain[EntitlementsKey.supabaseServiceRoleKey.rawValue] ?? ""
        }
        set {
            // keychain에 저장 (entitlements는 읽기 전용)
            keychain[EntitlementsKey.supabaseServiceRoleKey.rawValue] = newValue
        }
    }
    
    // MARK: - OpenAI Keys
    var openAIAPIKey: String {
        get {
            // 먼저 entitlements에서 읽기 시도
            if let key = Bundle.main.infoDictionary?[EntitlementsKey.openAIAPIKey.rawValue] as? String {
                return key
            }
            // 없으면 keychain에서 읽기
            return keychain[EntitlementsKey.openAIAPIKey.rawValue] ?? ""
        }
        set {
            // keychain에 저장 (entitlements는 읽기 전용)
            keychain[EntitlementsKey.openAIAPIKey.rawValue] = newValue
        }
    }
    
    var openAIBaseURL: String {
        get {
            // 먼저 entitlements에서 읽기 시도
            if let url = Bundle.main.infoDictionary?[EntitlementsKey.openAIBaseURL.rawValue] as? String {
                return url
            }
            // 없으면 keychain에서 읽기
            return keychain[EntitlementsKey.openAIBaseURL.rawValue] ?? "https://api.openai.com/v1"
        }
        set {
            // keychain에 저장 (entitlements는 읽기 전용)
            keychain[EntitlementsKey.openAIBaseURL.rawValue] = newValue
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
        // entitlements에 설정이 있으면 사용, 없으면 LocalConfig에서 기본값 설정
        if !isSupabaseConfigured {
            // 기본값 설정 (개발용)
            if supabaseURL.isEmpty {
                #if DEBUG
                supabaseURL = LocalConfig.supabaseURL
                #else
                supabaseURL = "YOUR_SUPABASE_URL"
                #endif
            }
            
            if supabaseAnonKey.isEmpty {
                #if DEBUG
                supabaseAnonKey = LocalConfig.supabaseAnonKey
                #else
                supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
                #endif
            }
        }
        
        if !isOpenAIConfigured {
            if openAIAPIKey.isEmpty {
                #if DEBUG
                openAIAPIKey = LocalConfig.openAIAPIKey
                #else
                openAIAPIKey = "YOUR_OPENAI_API_KEY"
                #endif
            }
        }
    }
    
    // MARK: - Clear Keys
    func clearAllKeys() {
        for key in EntitlementsKey.allCases {
            try? keychain.remove(key.rawValue)
        }
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
        
        // entitlements에서 읽어온 키인지 확인
        let supabaseFromEntitlements = Bundle.main.infoDictionary?[EntitlementsKey.supabaseURL.rawValue] != nil
        let openAIFromEntitlements = Bundle.main.infoDictionary?[EntitlementsKey.openAIAPIKey.rawValue] != nil
        
        print("   📱 Supabase from Entitlements: \(supabaseFromEntitlements)")
        print("   📱 OpenAI from Entitlements: \(openAIFromEntitlements)")
    }
}
