import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    var authService: AuthService
    private let firestoreService: FirestoreService
    
    // 사용자 정보
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var isAnonymousUser: Bool = false
    
    // 좋아요한 스타일 목록
    @Published var likedStyles: [LikedStyle] = []
    @Published var isLoadingLikedStyles: Bool = false
    @Published var likedStylesError: String?
    
    // 로그아웃 관련
    @Published var isLoggingOut: Bool = false
    @Published var showLogoutAlert: Bool = false
    
    // 일반적인 에러 메시지
    @Published var errorMessage: String?
    
    private var likedStylesListener: AnyCancellable?

    init(authService: AuthService? = nil, firestoreService: FirestoreService) {
        self.authService = authService ?? AuthService()
        self.firestoreService = firestoreService
    }
    
    func loadUserInfo() async {
        guard let user = authService.user else {
            userName = "사용자 정보 없음"
            userEmail = ""
            isAnonymousUser = false
            return
        }
        
        isAnonymousUser = user.isAnonymous
        
        if isAnonymousUser {
            userName = "게스트"
            userEmail = "게스트 계정"
            return
        }
        
        userEmail = user.email ?? ""
        
        // Firestore에서 닉네임 가져오기
        do {
            if let nickname = try await firestoreService.fetchUserNickname(uid: user.uid) {
                userName = nickname
            } else {
                // 닉네임이 없으면 이메일의 @ 앞부분 사용
                userName = userEmail.components(separatedBy: "@").first ?? "사용자"
            }
        } catch {
            print("Error fetching user nickname: \(error.localizedDescription)")
            userName = userEmail.components(separatedBy: "@").first ?? "사용자"
        }
    }
    
    func loadLikedStyles() {
        guard let userId = authService.currentUserId else {
            likedStyles = []
            return
        }
        
        isLoadingLikedStyles = true
        likedStylesError = nil
        
        // Firestore 실시간 리스너 설정
        firestoreService.fetchLikedStylesRealtime(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoadingLikedStyles = false
                
                switch result {
                case .success(let styles):
                    self.likedStyles = styles
                    self.likedStylesError = nil
                case .failure(let error):
                    self.likedStylesError = error.localizedDescription
                    print("Error loading liked styles: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func stopListeningToLikedStyles() {
        firestoreService.stopListeningToLikedStyles()
    }
    
    func showLogoutConfirmation() {
        showLogoutAlert = true
    }
    
    func logout() async {
        isLoggingOut = true
        errorMessage = nil
        
        // 좋아요 목록 리스너 정리
        stopListeningToLikedStyles()
        
        // Firebase에서 로그아웃
        authService.signOut()
        
        // AuthService의 signOut()이 동기 함수이므로 추가 처리 불필요
        // 로그아웃 후 UI 상태는 AuthService의 user 상태 변경으로 자동 처리됨
        
        isLoggingOut = false
    }
    
    // 좋아요 취소 (개별 아이템)
    func removeLikedStyle(_ style: LikedStyle) async {
        guard let userId = authService.currentUserId else { return }
        
        do {
            try await firestoreService.removeLikedStyle(userId: userId, styleId: style.id)
            // 실시간 리스너가 자동으로 목록을 업데이트함
        } catch {
            errorMessage = "좋아요 취소 중 오류가 발생했습니다: \(error.localizedDescription)"
        }
    }
} 