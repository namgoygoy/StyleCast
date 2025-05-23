import SwiftUI

struct LikedStyleDetailView: View {
    let likedStyle: LikedStyle
    @Environment(\.presentationMode) var presentationMode
    
    // 기본 설명 텍스트 (실제로는 LikedStyle 모델에 description을 추가하거나 다른 데이터 소스에서 가져올 수 있음)
    private var styleDescription: String {
        "이 스타일은 현재 트렌드를 반영한 세련된 룩으로, 다양한 상황에서 활용할 수 있습니다."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. 스타일 이미지 (큰 화면)
                if let uiImage = loadImageFromAsset(named: likedStyle.imageUrl) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(15)
                        .padding(.horizontal)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .cornerRadius(15)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("이미지를 불러올 수 없습니다")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                        .padding(.horizontal)
                }
                
                // 2. 스타일 정보
                VStack(alignment: .leading, spacing: 15) {
                    Text(likedStyle.name)
                        .font(.title)
                        .bold()
                    
                    Text(likedStyle.price)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("좋아요한 날짜: \(likedStyle.timestamp, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("스타일 설명")
                        .font(.headline)
                    
                    Text(styleDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // 3. 액션 버튼들
                VStack(spacing: 15) {
                    // Shop the Look 버튼 (현재는 기능 준비 중)
                    Button(action: {
                        // TODO: 실제 쇼핑 링크 연결 구현
                        print("Shop the Look tapped for \(likedStyle.name)")
                    }) {
                        HStack {
                            Image(systemName: "bag.fill")
                            Text("Shop the Look")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray) // 준비 중이므로 회색
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(true) // 현재는 비활성화
                    
                    Text("쇼핑 기능은 준비 중입니다.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("스타일 상세")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.title2)
        })
    }
    
    // Asset에서 이미지 로드하는 헬퍼 함수
    private func loadImageFromAsset(named imageName: String) -> UIImage? {
        // imageName이 Asset Catalog 이름이거나 파일 경로일 수 있음
        // 예: "cardigan" 또는 "outfit_detail/cardigan.jpg" -> "cardigan"으로 변환
        let cleanImageName = URL(fileURLWithPath: imageName).deletingPathExtension().lastPathComponent
        return UIImage(named: cleanImageName)
    }
}

// Preview
// struct LikedStyleDetailView_Previews: PreviewProvider {
//     static var previews: some View {
//         NavigationView {
//             LikedStyleDetailView(likedStyle: LikedStyle(
//                 originalId: "cardigan",
//                 imageUrl: "cardigan",
//                 name: "Cardigan",
//                 price: "$59",
//                 timestamp: Date()
//             ))
//         }
//     }
// } 