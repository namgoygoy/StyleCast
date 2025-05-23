import Foundation
import FirebaseFirestore // FirebaseFirestore 모듈을 import하여 Timestamp 타입을 사용
// import FirebaseFirestoreSwift // 제거

struct LikedStyle: Identifiable { // Codable 제거
    var id: String // 스타일의 이름 (예: "Cardigan"), 이걸 문서 ID로 사용
    var imageUrl: String // asset 경로 또는 원격 URL
    var name: String // 중복될 수 있지만, 편의상 포함 (id와 같을 수 있음)
    var price: String
    var timestamp: Date // Firestore Timestamp 대신 Swift Date 사용 (자동 변환됨)

    // id를 SwiftUI List에서 사용하기 위함. Firestore 문서 ID와는 별개.
    // Firestore에 저장할 때는 이 id 필드를 문서의 ID로 사용.

    // Firestore 문서 ID는 id 필드를 사용

    // CodingKeys 제거

    // Firestore 데이터로부터 객체를 생성하는 초기화 메서드
    init?(id: String, documentData: [String: Any]) {
        guard
            let imageUrl = documentData["imageUrl"] as? String,
            let name = documentData["name"] as? String,
            let price = documentData["price"] as? String,
            let timestamp = (documentData["timestamp"] as? Timestamp)?.dateValue() // Firestore Timestamp를 Date로 변환
        else {
            return nil
        }
        self.id = id // 문서 ID를 id로 사용
        self.imageUrl = imageUrl
        self.name = name
        self.price = price
        self.timestamp = timestamp
    }
    
    // 테스트나 다른 용도로 모든 필드를 받는 기본 초기화 메서드도 유지할 수 있습니다.
    init(id: String, imageUrl: String, name: String, price: String, timestamp: Date) {
        self.id = id
        self.imageUrl = imageUrl
        self.name = name
        self.price = price
        self.timestamp = timestamp
    }

    // 객체를 Firestore에 저장할 딕셔너리 형태로 변환하는 메서드
    func toDictionary() -> [String: Any] {
        return [
            "id": id, // id도 저장 (문서 ID와 별개로 필드에도 저장)
            "imageUrl": imageUrl,
            "name": name,
            "price": price,
            "timestamp": Timestamp(date: timestamp) // Date를 Firestore Timestamp로 변환
        ]
    }
} 