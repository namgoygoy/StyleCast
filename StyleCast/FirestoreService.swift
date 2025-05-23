import Foundation
import FirebaseFirestore
// import FirebaseFirestoreSwift // 제거

enum FirestoreError: Error {
    case userNotAuthenticated
    case documentNotFound
    // case encodingError(Error) // Codable 사용 안 하므로 직접적인 인코딩 에러는 줄어듬
    // case decodingError(Error) // Codable 사용 안 하므로 직접적인 디코딩 에러는 줄어듬
    case dataConversionError(String) // 데이터 변환 실패 에러 추가
    case writeError(Error)
    case unknown(Error)

    var localizedDescription: String {
        switch self {
        case .userNotAuthenticated: return "사용자가 인증되지 않았습니다."
        case .documentNotFound: return "문서를 찾을 수 없습니다."
        // case .encodingError(let err): return "데이터 인코딩 오류: \(err.localizedDescription)"
        // case .decodingError(let err): return "데이터 디코딩 오류: \(err.localizedDescription)"
        case .dataConversionError(let msg): return "데이터 변환 오류: \(msg)"
        case .writeError(let err): return "데이터 쓰기 오류: \(err.localizedDescription)"
        case .unknown(let err): return "알 수 없는 Firestore 오류: \(err.localizedDescription)"
        }
    }
}


class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    private var likedStylesListener: ListenerRegistration? // 좋아요 목록 실시간 리스너

    // MARK: - User Profile
    
    // 회원가입 시 사용자 프로필 정보 생성
    // AuthService의 signUp 성공 후 호출
    func createUserProfile(uid: String, email: String, nickname: String) async throws {
        let userRef = db.collection("users").document(uid)
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "nickname": nickname,
            "createdAt": Timestamp(date: Date()) // 서버 타임스탬프: FieldValue.serverTimestamp()
        ]
        do {
            try await userRef.setData(userData)
            print("User profile created for UID: \(uid)")
        } catch {
            throw FirestoreError.writeError(error)
        }
    }

    // 사용자 정보(닉네임 등) 가져오기
    // UserProfile 모델을 정의하여 사용할 수도 있음
    func fetchUserNickname(uid: String) async throws -> String? {
        let userRef = db.collection("users").document(uid)
        do {
            let document = try await userRef.getDocument()
            if document.exists, let data = document.data() {
                return data["nickname"] as? String
            } else {
                throw FirestoreError.documentNotFound
            }
        } catch let firestoreError as FirestoreError {
            throw firestoreError // 이미 FirestoreError인 경우 그대로 throw
        } catch {
            throw FirestoreError.unknown(error) // 그 외 에러
        }
    }
    
    // MARK: - Liked Styles

    // 스타일 '좋아요' 추가 (아이템 이름을 문서 ID로 사용)
    // 안드로이드의 StyleDetailActivity.StyleCardAdapter.toggleLike 와 유사
    func addLikedStyle(userId: String, style: LikedStyle) async throws {
        let likedStyleRef = db.collection("users").document(userId).collection("liked_styles").document(style.id)
        do {
            try await likedStyleRef.setData(style.toDictionary()) // toDictionary() 사용
            print("Style '\(style.name)' liked by user \(userId)")
        } catch {
            // setData가 실패하는 경우는 주로 권한 문제 또는 네트워크 문제
            throw FirestoreError.writeError(error)
        }
    }

    // 스타일 '좋아요' 취소
    func removeLikedStyle(userId: String, styleId: String) async throws {
        let likedStyleRef = db.collection("users").document(userId).collection("liked_styles").document(styleId)
        do {
            try await likedStyleRef.delete()
            print("Style '\(styleId)' unliked by user \(userId)")
        } catch {
            throw FirestoreError.writeError(error)
        }
    }

    // 특정 스타일 '좋아요' 상태 확인
    func checkIsStyleLiked(userId: String, styleId: String) async throws -> Bool {
        let likedStyleRef = db.collection("users").document(userId).collection("liked_styles").document(styleId)
        do {
            let document = try await likedStyleRef.getDocument()
            return document.exists
        } catch {
            if let firestoreError = error as? NSError, firestoreError.domain == FirestoreErrorDomain, firestoreError.code == FirestoreErrorCode.notFound.rawValue {
                 return false // 문서가 없으면 좋아요 안 한 것
            }
            throw FirestoreError.unknown(error)
        }
    }

    // 사용자의 모든 '좋아요'한 스타일 목록 가져오기 (실시간 업데이트)
    // LikesFragment의 loadLikedStyles와 유사
    // @Published 프로퍼티를 사용하여 SwiftUI 뷰에 자동으로 업데이트 전달
    func fetchLikedStylesRealtime(userId: String, completion: @escaping (Result<[LikedStyle], FirestoreError>) -> Void) {
        // 기존 리스너가 있다면 해제
        stopListeningToLikedStyles()

        let query = db.collection("users").document(userId).collection("liked_styles")
                      .order(by: "timestamp", descending: true)

        likedStylesListener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(.failure(.unknown(error)))
                return
            }

            guard let documents = querySnapshot?.documents else {
                completion(.success([])) // 문서가 없는 경우 빈 배열 반환
                return
            }

            let styles: [LikedStyle] = documents.compactMap { document -> LikedStyle? in
                // 문서 ID와 데이터를 사용하여 LikedStyle 객체 생성 시도
                guard let style = LikedStyle(id: document.documentID, documentData: document.data()) else {
                    print("Error converting document data to LikedStyle: \(document.documentID)")
                    return nil
                }
                return style
            }
            completion(.success(styles))
        }
    }
    
    // 실시간 리스너 중지
    func stopListeningToLikedStyles() {
        likedStylesListener?.remove()
        likedStylesListener = nil
        print("Stopped listening to liked styles changes.")
    }
} 