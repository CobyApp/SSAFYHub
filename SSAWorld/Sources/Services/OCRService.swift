import Foundation
import Vision
import UIKit

class OCRService: ObservableObject {
    static let shared = OCRService()
    
    private init() {}
    
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: recognizedText)
            }
            
            // 한국어 텍스트 인식 설정
            request.recognitionLanguages = ["ko-KR"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.processingFailed(error))
            }
        }
    }
    
    func parseMenuFromText(_ text: String) -> (itemsA: [String], itemsB: [String]) {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var itemsA: [String] = []
        var itemsB: [String] = []
        var currentType: MenuType = .unknown
        
        for line in lines {
            let lowercasedLine = line.lowercased()
            
            // A타입/B타입 구분
            if lowercasedLine.contains("a타입") || lowercasedLine.contains("a type") || lowercasedLine.contains("a-타입") {
                currentType = .typeA
                continue
            } else if lowercasedLine.contains("b타입") || lowercasedLine.contains("b type") || lowercasedLine.contains("b-타입") {
                currentType = .typeB
                continue
            }
            
            // 메뉴 항목 추가
            switch currentType {
            case .typeA:
                if !line.isEmpty && !line.contains("타입") {
                    itemsA.append(line)
                }
            case .typeB:
                if !line.isEmpty && !line.contains("타입") {
                    itemsB.append(line)
                }
            case .unknown:
                // 타입이 명시되지 않은 경우 A타입으로 간주
                if !line.isEmpty && !line.contains("타입") {
                    itemsA.append(line)
                }
            }
        }
        
        return (itemsA: itemsA, itemsB: itemsB)
    }
}

// MARK: - Enums
enum MenuType {
    case typeA
    case typeB
    case unknown
}

enum OCRError: Error, LocalizedError {
    case invalidImage
    case recognitionFailed(Error)
    case noTextFound
    case processingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "이미지를 처리할 수 없습니다."
        case .recognitionFailed(let error):
            return "텍스트 인식에 실패했습니다: \(error.localizedDescription)"
        case .noTextFound:
            return "이미지에서 텍스트를 찾을 수 없습니다."
        case .processingFailed(let error):
            return "이미지 처리에 실패했습니다: \(error.localizedDescription)"
        }
    }
}
