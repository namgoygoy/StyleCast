import SwiftUI
import SafariServices

struct StyleDetailView: View {
    @StateObject private var viewModel: StyleDetailViewModel
    @Environment(\.presentationMode) var presentationMode // 뒤로가기용
    
    // Safari View Controller 표시용
    @State private var showingSafari = false
    @State private var safariViewController: SFSafariViewController?
    
    init(styleData: StyleDetailData, firestoreService: FirestoreService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: StyleDetailViewModel(
            styleData: styleData,
            firestoreService: firestoreService,
            authService: authService
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. 헤더 정보
                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.styleData.outfitTitle)
                        .font(.title)
                        .bold()
                    
                    Text(viewModel.styleData.heading)
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    Text(viewModel.styleData.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // 2. 아이템 선택 목록 (가로 스크롤)
                VStack(alignment: .leading) {
                    Text("스타일 아이템")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Array(viewModel.styleData.items.enumerated()), id: \.offset) { index, item in
                                StyleItemCard(
                                    item: item,
                                    isSelected: index == viewModel.selectedItemIndex,
                                    isLiked: viewModel.likedItemsStatus[item.name] ?? false,
                                    onTap: {
                                        viewModel.selectedItemIndex = index
                                    },
                                    onLikeToggle: {
                                        Task {
                                            await viewModel.toggleLike(for: item)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 3. 선택된 아이템 정보 (큰 화면)
                if let selectedItem = viewModel.selectedItem {
                    SelectedItemDetailView(item: selectedItem)
                        .padding(.horizontal)
                }
                
                // 4. Shop the Look 버튼
                Button(action: {
                    if let safariVC = viewModel.getSafariViewController() {
                        safariViewController = safariVC
                        showingSafari = true
                    } else {
                        viewModel.openShopURL() // 외부 브라우저로 열기
                    }
                }) {
                    HStack {
                        Image(systemName: "bag.fill")
                        Text("Shop the Look")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(viewModel.selectedItem == nil)
                
                // 에러 메시지 표시
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("스타일 상세")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // 커스텀 뒤로가기 버튼 사용
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.title2)
        })
        .onAppear {
            Task {
                await viewModel.loadInitialData()
            }
        }
        .sheet(isPresented: $showingSafari) {
            if let safariVC = safariViewController {
                SafariView(safariViewController: safariVC)
            }
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        )
    }
}

// 개별 스타일 아이템 카드
struct StyleItemCard: View {
    let item: StyleItem
    let isSelected: Bool
    let isLiked: Bool
    let onTap: () -> Void
    let onLikeToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                // 아이템 이미지
                Image(item.imageName) // Asset Catalog에서 로드
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 150)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
                
                // 좋아요 버튼
                Button(action: onLikeToggle) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                        .font(.title3)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(item.price)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120)
        .onTapGesture(perform: onTap)
    }
}

// 선택된 아이템의 상세 정보
struct SelectedItemDetailView: View {
    let item: StyleItem

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("선택된 아이템")
                .font(.headline)
            
            HStack(spacing: 20) {
                Image(item.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.title2)
                        .bold()
                    Text(item.price)
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    // 추가 정보가 있다면 여기에 표시
                    Text("고품질 소재로 제작된 스타일리시한 아이템입니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

// Safari View Controller를 SwiftUI에서 사용하기 위한 래퍼
struct SafariView: UIViewControllerRepresentable {
    let safariViewController: SFSafariViewController

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return safariViewController
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // 업데이트할 내용 없음
    }
} 