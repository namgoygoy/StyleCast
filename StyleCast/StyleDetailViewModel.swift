import Foundation
import Combine
import SafariServices // 외부 URL 연결용
import UIKit

@MainActor
class StyleDetailViewModel: ObservableObject {
    private let firestoreService: FirestoreService
    private let authService: AuthService
    
    @Published var styleData: StyleDetailData
    @Published var selectedItemIndex: Int = 0 // 현재 선택된 아이템 인덱스
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // 좋아요 상태 추적을 위한 프로퍼티
    @Published var likedItemsStatus: [String: Bool] = [:] // 아이템 이름 -> 좋아요 상태

    init(styleData: StyleDetailData, firestoreService: FirestoreService, authService: AuthService) {
        self.styleData = styleData
        self.firestoreService = firestoreService
        self.authService = authService
    }
    
    func loadInitialData() async {
        // 각 아이템의 좋아요 상태 확인
        await checkLikeStatusForAllItems()
    }
    
    // 모든 아이템의 좋아요 상태 확인
    private func checkLikeStatusForAllItems() async {
        guard let userId = authService.currentUserId else { return }
        
        for item in styleData.items {
            do {
                let isLiked = try await firestoreService.checkIsStyleLiked(userId: userId, styleId: item.name)
                likedItemsStatus[item.name] = isLiked
            } catch {
                print("Error checking like status for \(item.name): \(error.localizedDescription)")
                likedItemsStatus[item.name] = false
            }
        }
    }
    
    // 특정 아이템의 좋아요 토글
    func toggleLike(for item: StyleItem) async {
        guard let userId = authService.currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let currentLikeStatus = likedItemsStatus[item.name] ?? false
        
        do {
            if currentLikeStatus {
                // 좋아요 취소
                try await firestoreService.removeLikedStyle(userId: userId, styleId: item.name)
                likedItemsStatus[item.name] = false
                print("Style '\(item.name)' unliked")
            } else {
                // 좋아요 추가
                let likedStyle = LikedStyle(
                    id: item.name, // item.name을 문서 ID로 사용
                    imageUrl: item.imageName, // Asset 이미지 이름 또는 경로
                    name: item.name,
                    price: item.price,
                    timestamp: Date()
                )
                try await firestoreService.addLikedStyle(userId: userId, style: likedStyle)
                likedItemsStatus[item.name] = true
                print("Style '\(item.name)' liked")
            }
        } catch {
            errorMessage = "좋아요 처리 중 오류가 발생했습니다: \(error.localizedDescription)"
            print("Error toggling like for \(item.name): \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // 현재 선택된 아이템 가져오기
    var selectedItem: StyleItem? {
        guard selectedItemIndex < styleData.items.count else { return nil }
        return styleData.items[selectedItemIndex]
    }
    
    // 선택된 아이템의 쇼핑 URL 열기
    func openShopURL() {
        guard let item = selectedItem,
              let url = URL(string: item.shopURL),
              UIApplication.shared.canOpenURL(url) else {
            errorMessage = "유효하지 않은 URL입니다."
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    // 또는 Safari View Controller를 사용하는 경우
    func getSafariViewController() -> SFSafariViewController? {
        guard let item = selectedItem,
              let url = URL(string: item.shopURL) else {
            return nil
        }
        return SFSafariViewController(url: url)
    }
} 