import Foundation
import Vision
import UIKit

class OCRService: ObservableObject {
    static let shared = OCRService()
    
    private init() {}
    
    // MARK: - OCR Processing
    func extractTextFromImage(_ image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR Error: \(error)")
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        try requestHandler.perform([request])
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            throw OCRError.noTextFound
        }
        
        let extractedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")
        
        return extractedText
    }
    
    // MARK: - Menu Parsing
    func parseMenuFromText(_ text: String) -> (itemsA: [String], itemsB: [String]) {
        let lines = text.components(separatedBy: .newlines)
        var itemsA: [String] = []
        var itemsB: [String] = []
        
        var currentType: MenuType = .unknown
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            // 메뉴 타입 감지
            if trimmedLine.contains("A타입") || trimmedLine.contains("A type") || trimmedLine.contains("A") {
                currentType = .typeA
                continue
            } else if trimmedLine.contains("B타입") || trimmedLine.contains("B type") || trimmedLine.contains("B") {
                currentType = .typeB
                continue
            }
            
            // 메뉴 아이템 추가
            switch currentType {
            case .typeA:
                itemsA.append(trimmedLine)
            case .typeB:
                itemsB.append(trimmedLine)
            case .unknown:
                // 타입이 명시되지 않은 경우 A타입으로 분류
                itemsA.append(trimmedLine)
            }
        }
        
        return (itemsA: itemsA, itemsB: itemsB)
    }
}

// MARK: - Menu Type
enum MenuType {
    case typeA
    case typeB
    case unknown
}

// MARK: - OCR Errors
enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "이미지를 처리할 수 없습니다."
        case .noTextFound:
            return "이미지에서 텍스트를 찾을 수 없습니다."
        case .processingFailed:
            return "OCR 처리에 실패했습니다."
        }
    }
}
