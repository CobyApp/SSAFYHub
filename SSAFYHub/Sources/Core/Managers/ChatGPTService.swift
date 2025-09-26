import Foundation
import UIKit
import SharedModels
import Dependencies

public class ChatGPTService: ObservableObject {
    static let shared = ChatGPTService()
    
    // MARK: - Properties
    private let apiKey: String
    private let baseURL: String
    @Dependency(\.errorHandler) var errorHandler
    @Dependency(\.logger) var logger
    @Dependency(\.networkManager) var networkManager
    
    public init() {
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
        
        logger.logAI(.info, "ChatGPTService 초기화 완료", additionalData: [
            "base_url": apiKeyManager.openAIBaseURL,
            "api_key_prefix": String(apiKey.prefix(20))
        ])
    }
    
    // MARK: - 메뉴 이미지 분석
    func analyzeMenuImage(_ image: UIImage) async throws -> [MealMenu] {
        logger.logAI(.info, "이미지 분석 시작", additionalData: [
            "image_size": "\(image.size.width)x\(image.size.height)",
            "image_scale": image.scale
        ])
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            logger.logAI(.error, "이미지 변환 실패")
            throw AppError.ai(.imageConversionFailed)
        }
        
        let base64Image = imageData.base64EncodedString()
        logger.logAI(.debug, "Base64 이미지 변환 완료", additionalData: [
            "base64_length": base64Image.count,
            "compression_quality": 0.8
        ])
        
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
        
        logger.logAI(.debug, "프롬프트 전송", additionalData: [
            "prompt_length": prompt.count
        ])
        
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
        
        // 네트워크 매니저를 사용한 요청
        let endpoint = DefaultAPIEndpoint(
            baseURL: baseURL.replacingOccurrences(of: "/chat/completions", with: ""),
            path: "/chat/completions",
            method: .POST,
            headers: [
                "Authorization": "Bearer \(apiKey)"
            ],
            body: try JSONEncoder().encode(requestBody),
            timeout: 60.0
        )
        
        logger.logAI(.info, "ChatGPT API 요청 시작", additionalData: [
            "url": endpoint.baseURL + endpoint.path,
            "request_size": try JSONEncoder().encode(requestBody).count,
            "model": "gpt-4o-mini"
        ])
        
        // NetworkManager를 사용한 요청 (재시도 로직은 NetworkManager에서 처리)
        do {
            let chatGPTResponse = try await networkManager.request(endpoint, responseType: ChatGPTResponse.self)
            
            guard let firstChoice = chatGPTResponse.choices.first,
                  let message = firstChoice.message,
                  let content = message.content else {
                logger.logAI(.error, "응답에서 텍스트 내용을 찾을 수 없음", additionalData: [
                    "response_structure": String(describing: chatGPTResponse)
                ])
                throw AppError.ai(.noContentReceived)
            }
            
            logger.logAI(.info, "ChatGPT API 응답 파싱 성공", additionalData: [
                "response_length": content.count,
                "response_preview": String(content.prefix(200))
            ])
            
            // JSON 응답에서 메뉴 데이터 추출
            return try parseMenuData(from: content)
            
        } catch {
            logger.logAI(.error, "ChatGPT API 요청 실패", additionalData: [
                "error": error.localizedDescription
            ])
            throw error
        }
    }
    
    // MARK: - 메뉴 데이터 파싱
    private func parseMenuData(from text: String) throws -> [MealMenu] {
        logger.logAI(.debug, "메뉴 데이터 파싱 시작")
        
        // JSON 부분 추출
        guard let startIndex = text.firstIndex(of: "{"),
              let endIndex = text.lastIndex(of: "}") else {
            logger.logAI(.error, "JSON 시작/끝 문자를 찾을 수 없음")
            throw AppError.ai(.parsingFailed)
        }
        
        let jsonString = String(text[startIndex...endIndex])
        logger.logAI(.debug, "JSON 추출 완료", additionalData: [
            "json_length": jsonString.count
        ])
        
        do {
            let jsonData = jsonString.data(using: .utf8)!
            let geminiMenuData = try JSONDecoder().decode(GeminiMenuData.self, from: jsonData)
            
            var menus: [MealMenu] = []
            let currentUser = "AI_Extracted"
            
            for geminiMenu in geminiMenuData.menus {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                guard let date = dateFormatter.date(from: geminiMenu.date) else {
                    logger.logAI(.warning, "날짜 파싱 실패", additionalData: [
                        "invalid_date": geminiMenu.date
                    ])
                    continue
                }
                
                // MealMenu 모델 생성
                let menu = MealMenu(
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
            logger.logAI(.error, "JSON 파싱 실패", additionalData: [
                "error": error.localizedDescription
            ])
            throw AppError.ai(.parsingFailed)
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

