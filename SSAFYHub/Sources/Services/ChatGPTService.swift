import Foundation
import UIKit

class ChatGPTService: ObservableObject {
    static let shared = ChatGPTService()
    
    // MARK: - Properties
    private let apiKey: String
    private let baseURL: String
    
    private init() {
        // APIKeyManager에서 OpenAI 설정 가져오기
        let apiKeyManager = APIKeyManager.shared
        
        // 기본 키 설정 (첫 실행 시)
        apiKeyManager.setupDefaultKeys()
        
        self.apiKey = apiKeyManager.openAIAPIKey
        self.baseURL = apiKeyManager.openAIBaseURL + "/chat/completions"
        
        // 설정 유효성 검사
        guard apiKeyManager.isOpenAIConfigured else {
            fatalError("❌ ChatGPTService: OpenAI 설정이 유효하지 않습니다. APIKeyManager를 확인해주세요.")
        }
        
        print("🔧 ChatGPTService: 초기화 완료")
        print("🔧 ChatGPTService: Base URL: \(apiKeyManager.openAIBaseURL)")
        print("🔧 ChatGPTService: API Key: \(apiKey.prefix(20))...")
    }
    
    // MARK: - 메뉴 이미지 분석
    func analyzeMenuImage(_ image: UIImage) async throws -> [Menu] {
        print("🚀 ChatGPTService: 이미지 분석 시작")
        print("📸 이미지 크기: \(image.size)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ ChatGPTService: 이미지 변환 실패")
            throw ChatGPTError.imageConversionFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        print("📊 Base64 이미지 길이: \(base64Image.count)")
        
        let prompt = """
        이 이미지는 삼성화재 유성캠퍼스의 주간 식단표입니다. 
        다음 형식으로 정확하게 파싱해주세요:
        
        요구사항:
        1. 월요일부터 금요일까지만 분석 (주말 제외)
        2. 중식(점심) 메뉴만 추출
        3. A타입과 B타입을 구분하여 추출
        4. 각 메뉴 항목을 배열로 정리
        5. 날짜는 YYYY-MM-DD 형식으로 변환
        
        출력 형식:
        {
          "menus": [
            {
              "date": "2025-08-11",
              "dayOfWeek": "월요일",
              "itemsA": ["혼합잡곡밥", "뼈없는감자탕", "너비아니구이&파채", "매콤잡채", "브로컬리숙회", "깍두기"],
              "itemsB": ["치킨커틀렛&식빵러스크", "크림스프", "후리카케양념밥", "콘샐러드", "오이피클", "깍두기"]
            }
          ]
        }
        
        정확하게 파싱해주세요.
        """
        
        print("📝 프롬프트 전송: \(prompt)")
        
        let requestBody = ChatGPTRequest(
            model: "gpt-4o-mini", // GPT-4o-mini 모델 사용 (이미지 분석 지원)
            messages: [
                ChatGPTMessage(
                    role: "user",
                    content: [
                        ChatGPTContent(
                            type: "text",
                            text: prompt
                        ),
                        ChatGPTContent(
                            type: "image_url",
                            imageUrl: ChatGPTImageURL(
                                url: "data:image/jpeg;base64,\(base64Image)"
                            )
                        )
                    ]
                )
            ],
            maxTokens: 1000,
            temperature: 0.1
        )
        
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        print("🌐 ChatGPT API 요청 시작")
        print("🔗 URL: \(url)")
        print("📤 요청 크기: \(request.httpBody?.count ?? 0) bytes")
        
        // 재시도 로직 추가
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ ChatGPTService: HTTP 응답이 아님")
                    throw ChatGPTError.apiRequestFailed
                }
                
                print("📥 ChatGPT API 응답 수신 (시도 \(attempt)/\(maxRetries))")
                print("📊 상태 코드: \(httpResponse.statusCode)")
                print("📦 응답 크기: \(data.count) bytes")
                
                if httpResponse.statusCode == 200 {
                    let chatGPTResponse = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
                    
                    guard let firstChoice = chatGPTResponse.choices.first,
                          let message = firstChoice.message,
                          let content = message.content else {
                        print("❌ ChatGPTService: 응답에서 텍스트 내용을 찾을 수 없음")
                        print("📋 응답 구조: \(chatGPTResponse)")
                        throw ChatGPTError.noContentReceived
                    }
                    
                    print("✅ ChatGPTService: 응답 파싱 성공")
                    print("📝 응답 텍스트 길이: \(content.count)")
                    print("📝 응답 텍스트 미리보기: \(String(content.prefix(200)))...")
                    
                    // JSON 응답에서 메뉴 데이터 추출
                    return try parseMenuData(from: content)
                    
                } else if httpResponse.statusCode == 429 {
                    // 할당량 초과 - 재시도 대기
                    print("⚠️ ChatGPTService: 할당량 초과 (429), 재시도 대기 중...")
                    
                    if attempt < maxRetries {
                        // 기본 재시도 대기 시간
                        let baseDelay = attempt * 5 // 5초, 10초, 15초
                        print("⏰ 기본 재시도 대기 시간: \(baseDelay)초")
                        try await Task.sleep(nanoseconds: UInt64(baseDelay) * 1_000_000_000)
                        continue
                    } else {
                        print("❌ ChatGPTService: 최대 재시도 횟수 초과")
                        lastError = ChatGPTError.apiRequestFailed
                        break
                    }
                    
                } else {
                    print("❌ ChatGPTService: API 요청 실패 - 상태 코드: \(httpResponse.statusCode)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("❌ 에러 응답: \(errorString)")
                    }
                    lastError = ChatGPTError.apiRequestFailed
                    break
                }
                
            } catch {
                print("❌ ChatGPTService: 네트워크 에러 (시도 \(attempt)/\(maxRetries)): \(error)")
                lastError = error
                
                if attempt < maxRetries {
                    // 네트워크 에러 시 짧은 대기 후 재시도
                    try await Task.sleep(nanoseconds: UInt64(attempt * 2) * 1_000_000_000)
                    continue
                } else {
                    break
                }
            }
        }
        
        // 모든 재시도 실패
        throw lastError ?? ChatGPTError.apiRequestFailed
    }
    
    // MARK: - 메뉴 데이터 파싱
    private func parseMenuData(from text: String) throws -> [Menu] {
        print("🔍 메뉴 데이터 파싱 시작")
        
        // JSON 부분 추출
        guard let startIndex = text.firstIndex(of: "{"),
              let endIndex = text.lastIndex(of: "}") else {
            print("❌ JSON 시작/끝 문자를 찾을 수 없음")
            throw ChatGPTError.parsingFailed
        }
        
        let jsonString = String(text[startIndex...endIndex])
        print("📋 추출된 JSON: \(jsonString)")
        
        do {
            let jsonData = jsonString.data(using: .utf8)!
            let geminiMenuData = try JSONDecoder().decode(GeminiMenuData.self, from: jsonData)
            
            var menus: [Menu] = []
            let currentUser = "AI_Extracted"
            
            for geminiMenu in geminiMenuData.menus {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                guard let date = dateFormatter.date(from: geminiMenu.date) else {
                    print("⚠️ 날짜 파싱 실패: \(geminiMenu.date)")
                    continue
                }
                
                // Menu 모델 생성
                let menu = Menu(
                    id: UUID().uuidString,
                    date: date,
                    campus: .daejeon, // 현재는 대전캠퍼스만 지원
                    itemsA: geminiMenu.itemsA,
                    itemsB: geminiMenu.itemsB,
                    updatedAt: Date(),
                    updatedBy: currentUser
                )
                
                menus.append(menu)
            }
            
            return menus
            
        } catch {
            print("❌ JSON 파싱 실패: \(error)")
            throw ChatGPTError.parsingFailed
        }
    }
}

// MARK: - ChatGPT API 요청 모델
struct ChatGPTRequest: Codable {
    let model: String
    let messages: [ChatGPTMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
        case temperature
    }
}

struct ChatGPTMessage: Codable {
    let role: String
    let content: [ChatGPTContent]
}

struct ChatGPTContent: Codable {
    let type: String
    let text: String?
    let imageUrl: ChatGPTImageURL?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case imageUrl = "image_url"
    }
    
    init(type: String, text: String) {
        self.type = type
        self.text = text
        self.imageUrl = nil
    }
    
    init(type: String, imageUrl: ChatGPTImageURL) {
        self.type = type
        self.text = nil
        self.imageUrl = imageUrl
    }
}

struct ChatGPTImageURL: Codable {
    let url: String
}

// MARK: - ChatGPT API 응답 모델
struct ChatGPTResponse: Codable {
    let choices: [ChatGPTChoice]
}

struct ChatGPTChoice: Codable {
    let message: ChatGPTResponseMessage?
}

struct ChatGPTResponseMessage: Codable {
    let content: String?
}

// MARK: - 메뉴 데이터 (기존 Gemini와 동일한 구조)
struct GeminiMenuData: Codable {
    let menus: [GeminiMenu]
}

struct GeminiMenu: Codable {
    let date: String
    let dayOfWeek: String
    let itemsA: [String]
    let itemsB: [String]
}

// MARK: - 에러 타입
enum ChatGPTError: Error, LocalizedError {
    case imageConversionFailed
    case apiRequestFailed
    case noContentReceived
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "이미지 변환에 실패했습니다."
        case .apiRequestFailed:
            return "ChatGPT API 요청에 실패했습니다."
        case .noContentReceived:
            return "ChatGPT에서 응답을 받지 못했습니다."
        case .parsingFailed:
            return "응답 파싱에 실패했습니다."
        }
    }
}
