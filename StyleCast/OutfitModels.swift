import Foundation
import SwiftUI // Image 사용을 위해 (또는 UIKit의 UIImage)

// 안드로이드 MainActivity의 TemperatureCategory 와 유사
enum TemperatureCategory: String, CaseIterable, Identifiable {
    case cold = "5도 이하" // 안드로이드: TEMP_COLD (<= 5.0)
    case cool = "6도 ~ 16도" // 안드로이드: TEMP_COOL_MAX (<= 16.0)
    case mild = "17도 ~ 27도" // 안드로이드: TEMP_MILD_MAX (<= 27.0)
    case hot  = "28도 이상"  // 안드로이드: TEMP_HOT (>= 28.0)

    var id: String { self.rawValue }

    // 온도에 따른 카테고리 결정 로직
    // 안드로이드: getTemperatureCategory(minTemp: Double, maxTemp: Double)
    // 여기서는 현재 온도를 기준으로 단순화 (필요시 최저/최고 온도를 인자로 받도록 수정)
    static func from(temperature: Double) -> TemperatureCategory {
        switch temperature {
        case ..<6: // 5도 이하 (6도 미만)
            return .cold
        case 6..<17: // 6도 ~ 16도 (17도 미만)
            return .cool
        case 17..<28: // 17도 ~ 27도 (28도 미만)
            return .mild
        default: // 28도 이상
            return .hot
        }
    }

    // Asset Catalog 이미지 이름에 사용될 폴더명 반환
    // 안드로이드: getTemperatureFolder
    var folderName: String {
        switch self {
        case .cold: return "cold"
        case .cool: return "cool"
        case .mild: return "mild"
        case .hot:  return "hot"
        }
    }
    
    // 사용자에게 보여줄 설명
    var recommendationMessage: String {
        switch self {
        case .cold: return "오늘은 겨울철 패션을 추천드립니다. (5도 이하)"
        case .cool: return "오늘은 가을/초봄 패션을 추천드립니다. (6~16도)"
        case .mild: return "오늘은 봄/가을 패션을 추천드립니다. (17~27도)"
        case .hot:  return "오늘은 여름철 패션을 추천드립니다. (28도 이상)"
        }
    }
}

// 스타일 카테고리 enum 추가
enum Style: String, CaseIterable, Identifiable {
    case street = "스트릿"
    case minimal = "미니멀"
    
    var id: String { self.rawValue }
    
    // Asset Catalog 이미지 이름에 사용될 폴더명 반환
    var folderName: String {
        switch self {
        case .street: return "" // 기본 스타일 (폴더명 없음)
        case .minimal: return "minimal"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .street: return "figure.walk"
        case .minimal: return "minus.circle"
        }
    }
}

// 안드로이드 MainActivity의 Gender 와 유사
enum Gender: String, CaseIterable, Identifiable {
    case men = "남성"
    case women = "여성"

    var id: String { self.rawValue }

    // Asset Catalog 이미지 이름에 사용될 폴더명 반환
    // 안드로이드: getGenderFolder
    var folderName: String {
        switch self {
        case .men: return "men"
        case .women: return "women"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .men: return "person"
        case .women: return "person.fill"
        }
    }
}

// 옷차림 추천 아이템 모델 (안드로이드 MainActivity.OutfitItem 과 유사)
struct OutfitItem: Identifiable {
    let id = UUID() // 각 아이템을 고유하게 식별 (SwiftUI List 등에서 사용)
    let imageName: String // Asset Catalog에 저장된 이미지 이름
    let title: String
    let description: String // 예: "겨울철 추천 스타일 (5도 이하)"
    // 실제 Image 객체는 View에서 imageName을 사용하여 로드
} 