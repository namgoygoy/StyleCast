import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: ProfileViewModel
    @State private var showingLikedStyles = false
    
    init() {
        // ProfileViewModel 초기화 시 필요한 서비스들을 주입
        _viewModel = StateObject(wrappedValue: ProfileViewModel(
            authService: nil, // onAppear에서 EnvironmentObject로 설정
            firestoreService: FirestoreService()
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 프로필 헤더
                ProfileHeaderView(viewModel: viewModel)
                
                Divider()
                
                // 2. 좋아요한 스타일 섹션
                LikedStylesSectionView(
                    viewModel: viewModel,
                    onViewAll: {
                        showingLikedStyles = true
                    }
                )
                
                Divider()
                
                // 3. 설정 및 기타 옵션
                SettingsSectionView(viewModel: viewModel)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("프로필")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // AuthService를 ViewModel에 주입 (EnvironmentObject 사용)
            viewModel.authService = authService
            
            Task {
                await viewModel.loadUserInfo()
                viewModel.loadLikedStyles()
            }
        }
        .onDisappear {
            viewModel.stopListeningToLikedStyles()
        }
        .sheet(isPresented: $showingLikedStyles) {
            NavigationView {
                LikedStylesListView(viewModel: viewModel)
                    .navigationTitle("좋아요한 스타일")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button("완료") {
                        showingLikedStyles = false
                    })
            }
        }
        .alert("로그아웃", isPresented: $viewModel.showLogoutAlert) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive) {
                Task {
                    await viewModel.logout()
                }
            }
        } message: {
            Text("정말 로그아웃하시겠습니까?")
        }
        
        // 에러 메시지 표시
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .font(.caption)
                .padding()
        }
    }
}

// 프로필 헤더 뷰
struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // 프로필 아이콘
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                if viewModel.isAnonymousUser {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                }
            }
            
            // 사용자 정보
            VStack(spacing: 5) {
                Text(viewModel.userName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(viewModel.userEmail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if viewModel.isAnonymousUser {
                    Text("게스트 계정")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }
        }
    }
}

// 좋아요한 스타일 섹션
struct LikedStylesSectionView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("좋아요한 스타일")
                    .font(.headline)
                Spacer()
                Button("전체보기") {
                    onViewAll()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if viewModel.isLoadingLikedStyles {
                ProgressView("로딩 중...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.likedStyles.isEmpty {
                VStack {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("좋아요한 스타일이 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // 최근 3개 스타일만 미리보기로 표시
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.likedStyles.prefix(3))) { style in
                            LikedStylePreviewCard(style: style)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }
}

// 좋아요한 스타일 미리보기 카드
struct LikedStylePreviewCard: View {
    let style: LikedStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage = loadImageFromAsset(named: style.imageUrl) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 100)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(style.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 80, alignment: .leading)
        }
    }
    
    private func loadImageFromAsset(named imageName: String) -> UIImage? {
        let cleanImageName = URL(fileURLWithPath: imageName).deletingPathExtension().lastPathComponent
        return UIImage(named: cleanImageName)
    }
}

// 설정 섹션
struct SettingsSectionView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("설정")
                .font(.headline)
            
            VStack(spacing: 12) {
                // 로그아웃 버튼
                Button(action: {
                    viewModel.showLogoutConfirmation()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        Text("로그아웃")
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoggingOut)
                
                if viewModel.isLoggingOut {
                    ProgressView("로그아웃 중...")
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(AuthService())
        }
    }
} 