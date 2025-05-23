import SwiftUI

struct LikedStylesListView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var selectedStyle: LikedStyle?
    @State private var showingStyleDetail = false
    
    // 그리드 레이아웃 설정 (2열)
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        Group {
            if viewModel.isLoadingLikedStyles {
                ProgressView("좋아요 목록 로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.likedStylesError {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("오류: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button("다시 시도") {
                        viewModel.loadLikedStyles()
                    }
                    .padding(.top)
                }
                .padding()
            } else if viewModel.likedStyles.isEmpty {
                VStack {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("좋아요한 스타일이 없습니다.")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("메인 화면에서 마음에 드는 스타일을 좋아요 해보세요!")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 5)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(viewModel.likedStyles) { style in
                            LikedStyleCard(
                                style: style,
                                onTap: {
                                    selectedStyle = style
                                    showingStyleDetail = true
                                },
                                onRemove: {
                                    Task {
                                        await viewModel.removeLikedStyle(style)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingStyleDetail) {
            if let style = selectedStyle {
                NavigationView {
                    LikedStyleDetailView(likedStyle: style)
                }
            }
        }
    }
}

// 좋아요한 스타일 카드
struct LikedStyleCard: View {
    let style: LikedStyle
    let onTap: () -> Void
    let onRemove: () -> Void
    
    @State private var showingRemoveAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // 스타일 이미지
                if let uiImage = loadImageFromAsset(named: style.imageUrl) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                        .cornerRadius(10)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                Text("이미지 없음")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                // 좋아요 취소 버튼
                Button(action: {
                    showingRemoveAlert = true
                }) {
                    Image(systemName: "heart.slash.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            
            // 스타일 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(style.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(style.price)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Text(style.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .onTapGesture(perform: onTap)
        .alert("좋아요 취소", isPresented: $showingRemoveAlert) {
            Button("취소", role: .cancel) { }
            Button("확인", role: .destructive) {
                onRemove()
            }
        } message: {
            Text("이 스타일을 좋아요 목록에서 제거하시겠습니까?")
        }
    }
    
    // Asset에서 이미지 로드하는 헬퍼 함수
    private func loadImageFromAsset(named imageName: String) -> UIImage? {
        let cleanImageName = URL(fileURLWithPath: imageName).deletingPathExtension().lastPathComponent
        return UIImage(named: cleanImageName)
    }
} 