import SwiftUI

struct LikedStylesView: View {
    @EnvironmentObject var authService: AuthService // 현재 사용자 ID 접근용
    @StateObject private var firestoreService = FirestoreService() // 좋아요 데이터 로드용
    
    @State private var likedStyles: [LikedStyle] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("좋아요 목록 로딩 중...")
                } else if let errorMsg = errorMessage {
                    Text("오류: \(errorMsg)")
                } else if likedStyles.isEmpty {
                    Text("좋아요한 스타일이 없습니다.")
                } else {
                    List(likedStyles) { style in // LikedStyle이 Identifiable을 따르므로 직접 사용 가능
                        HStack {
                            // 이미지 표시 (Asset 또는 URL) - 실제 이미지 로딩 로직 필요
                            // 예시: Image(style.imageUrl).resizable().frame(width: 50, height: 50)
                            //      AsyncImage(url: URL(string: style.imageUrl)) { image in image.resizable() }
                            //                       placeholder: { ProgressView() }
                            //                       .frame(width: 50, height: 50)
                            
                            // assets 이미지 로딩 예시 (실제 경로 및 에러 처리 필요)
                            if let uiImage = loadImageFromAssets(named: style.imageUrl) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                            } else {
                                Rectangle() // Placeholder
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .overlay(Text("No\nImg").font(.caption2).multilineTextAlignment(.center))
                            }


                            VStack(alignment: .leading) {
                                Text(style.name).font(.headline)
                                Text(style.price).font(.subheadline)
                                Text("좋아요: \(style.timestamp, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            // 좋아요 취소 버튼 (필요한 경우)
                            Button {
                                Task {
                                    await unlikeStyle(styleId: style.id)
                                }
                            } label: {
                                Image(systemName: "heart.slash.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        // .onTapGesture { // 상세 화면으로 이동
                        //     // NavigationLink 등 사용
                        // }
                    }
                }
            }
            .navigationTitle("좋아요한 스타일")
            .onAppear(perform: loadData)
            .onDisappear {
                firestoreService.stopListeningToLikedStyles() // 화면 사라질 때 리스너 정리
            }
        }
    }

    func loadData() {
        guard let userId = authService.currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return
        }
        isLoading = true
        errorMessage = nil
        
        firestoreService.fetchLikedStylesRealtime(userId: userId) { result in
            isLoading = false
            switch result {
            case .success(let styles):
                self.likedStyles = styles
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // 좋아요 취소 함수 예시
    func unlikeStyle(styleId: String) async {
        guard let userId = authService.currentUserId else { return }
        do {
            try await firestoreService.removeLikedStyle(userId: userId, styleId: styleId)
            // 실시간 리스너가 목록을 자동으로 업데이트하므로 별도 UI 갱신 불필요
            print("Style \(styleId) unliked.")
        } catch {
            print("Error unliking style: \(error.localizedDescription)")
            // 사용자에게 에러 메시지 표시
        }
    }

    // Assets에서 이미지 로드하는 헬퍼 함수 (실제 구현 필요)
    // 안드로이드의 assets/outfit_detail/cardigan.jpg 와 같은 경로를 어떻게 iOS에서 관리할지에 따라 달라짐
    // 여기서는 단순 파일 이름을 받는다고 가정
    func loadImageFromAssets(named imageName: String) -> UIImage? {
        // 예시: "outfit_detail/cardigan.jpg" -> "cardigan" (확장자 제거)
        // 실제로는 Asset Catalog에 추가하거나 Bundle에서 직접 로드
        let nameWithoutExtension = URL(fileURLWithPath: imageName).deletingPathExtension().lastPathComponent
        return UIImage(named: nameWithoutExtension) // Asset Catalog에 해당 이름의 이미지가 있어야 함
    }
} 