import Foundation

// 개별 스타일 아이템 (가디건, 바지 등)
struct StyleItem: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String // 예: "Cardigan", "Pants"
    let imageName: String // Asset Catalog 이미지 이름
    let price: String // 예: "$59"
    let shopURL: String // 쇼핑몰 URL
    var isLiked: Bool = false // 좋아요 상태 (UI에서 관리)
}

// 스타일 상세 화면에 전달할 데이터
struct StyleDetailData {
    let outfitTitle: String // 예: "남성 기본 스타일"
    let heading: String // 부제목
    let description: String // 스타일 설명
    let items: [StyleItem] // 개별 아이템들
} 