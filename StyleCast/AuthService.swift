import Foundation
import FirebaseAuth // FirebaseAuth import
import Combine // ObservableObject, @Published 사용을 위해

// 인증 관련 에러 정의
enum AuthError: Error {
    case weakPassword
    case emailAlreadyInUse
    case invalidEmail
    case userNotFound
    case wrongPassword
    case anounymousSignInFailed(String)
    case signInFailed(String)
    case signUpFailed(String)
    case signOutFailed(String)
    case unknown(String) // 기타 Firebase Auth 에러

    var localizedDescription: String {
        switch self {
        case .weakPassword: return "비밀번호는 6자 이상이어야 합니다."
        case .emailAlreadyInUse: return "이미 사용 중인 이메일입니다."
        case .invalidEmail: return "유효하지 않은 이메일 형식입니다."
        case .userNotFound: return "등록되지 않은 사용자입니다."
        case .wrongPassword: return "잘못된 비밀번호입니다."
        case .anounymousSignInFailed(let msg): return "게스트 로그인 실패: \(msg)"
        case .signInFailed(let msg): return "로그인 실패: \(msg)"
        case .signUpFailed(let msg): return "회원가입 실패: \(msg)"
        case .signOutFailed(let msg): return "로그아웃 실패: \(msg)"
        case .unknown(let msg): return "알 수 없는 오류: \(msg)"
        }
    }
}

@MainActor // 클래스 전체를 MainActor로 지정하여 모든 메서드가 메인 스레드에서 실행되도록 함
class AuthService: ObservableObject {
    @Published var user: User? // 현재 Firebase 사용자
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var handle: AuthStateDidChangeListenerHandle?
    private let firestoreService = FirestoreService() // FirestoreService 인스턴스 추가

    init() {
        // 앱 시작 시 사용자의 로그인 상태 변경을 감지하는 리스너 등록
        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            self.user = user
            if user != nil {
                print("User is signed in with uid: \(user!.uid), email: \(user!.email ?? "N/A"), isAnonymous: \(user!.isAnonymous)")
            } else {
                print("User is signed out.")
            }
        }
    }

    deinit {
        // 리스너 해제
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // 이메일/비밀번호로 로그인
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = authResult.user
            isLoading = false
        } catch let error as NSError { // Firebase 에러는 NSError로 캐치됨
            isLoading = false
            let authErrorCode = AuthErrorCode(_bridgedNSError: error)
            switch authErrorCode?.code { // 옵셔널 체이닝 사용
            case .invalidEmail:
                self.errorMessage = AuthError.invalidEmail.localizedDescription
            case .userNotFound, .userDisabled: // userNotFound 또는 userDisabled
                self.errorMessage = AuthError.userNotFound.localizedDescription
            case .wrongPassword:
                self.errorMessage = AuthError.wrongPassword.localizedDescription
            default:
                self.errorMessage = AuthError.signInFailed(error.localizedDescription).localizedDescription
            }
            print("Sign in error: \(error.localizedDescription), code: \(authErrorCode?.code.rawValue ?? -1)")
        }
        isLoading = false // @Published 프로퍼티 업데이트
    }

    // 이메일/비밀번호로 회원가입
    // 회원가입 성공 시 Firestore에 사용자 정보를 저장하는 로직은 다음 모듈(사용자 데이터 관리)에서 추가
    func signUp(email: String, password: String, nickname: String = "") async {
        isLoading = true
        errorMessage = nil
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = authResult.user // @Published 프로퍼티 업데이트
            
            let uid = authResult.user.uid // 직접 할당으로 수정
            
            // 회원가입 성공 후 Firestore에 사용자 프로필 정보 저장
            // uid를 성공적으로 가져온 후 닉네임 유무에 따라 처리
            if !nickname.isEmpty {
                do {
                    try await firestoreService.createUserProfile(uid: uid, email: email, nickname: nickname)
                    print("User profile successfully created for UID: \(uid)")
                } catch let firestoreError as FirestoreError {
                    print("Failed to create user profile in Firestore: \(firestoreError.localizedDescription) for UID: \(uid)")
                    // self.errorMessage = "프로필 정보 저장에 실패했습니다: \(firestoreError.localizedDescription)"
                } catch {
                    print("An unexpected error occurred while creating user profile for UID: \(uid): \(error.localizedDescription)")
                }
            } else {
                print("Nickname is empty. Skipping Firestore profile creation for UID: \(uid).")
            }
            
            // isLoading = false 는 모든 비동기 작업이 끝난 후 또는 각 catch 블록에서 설정되어야 함
            // 현재는 signUp 함수의 최하단에 isLoading = false 가 위치하도록 구조화

        } catch let error as NSError { // Auth 에러 처리
            // isLoading = false 여기서도 설정 필요 (또는 함수의 맨 마지막에 한번만)
            let authErrorCode = AuthErrorCode(_bridgedNSError: error)
            switch authErrorCode?.code {
            case .weakPassword:
                self.errorMessage = AuthError.weakPassword.localizedDescription
            case .emailAlreadyInUse:
                self.errorMessage = AuthError.emailAlreadyInUse.localizedDescription
            case .invalidEmail:
                self.errorMessage = AuthError.invalidEmail.localizedDescription
            default:
                self.errorMessage = AuthError.signUpFailed(error.localizedDescription).localizedDescription
            }
            print("Sign up error: \(error.localizedDescription), code: \(authErrorCode?.code.rawValue ?? -1)")
        } catch { // Auth.auth().createUser에서 NSError가 아닌 다른 Error가 발생한 경우 (드묾)
            self.errorMessage = AuthError.signUpFailed("An unexpected error occurred during signup: \(error.localizedDescription)").localizedDescription
            print("Unexpected sign up error: \(error.localizedDescription)")
        }
        isLoading = false // 모든 작업 완료 후 또는 에러 발생 시점에 isLoading 상태 업데이트
    }

    // 익명(게스트) 로그인
    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil
        do {
            let authResult = try await Auth.auth().signInAnonymously()
            self.user = authResult.user
            isLoading = false
        } catch let error {
            isLoading = false
            self.errorMessage = AuthError.anounymousSignInFailed(error.localizedDescription).localizedDescription
            print("Anonymous sign in error: \(error.localizedDescription)")
        }
        isLoading = false // @Published 프로퍼티 업데이트
    }

    // 로그아웃
    func signOut() {
        isLoading = true
        errorMessage = nil
        do {
            try Auth.auth().signOut()
            // self.user는 리스너에 의해 자동으로 nil로 설정됨
            isLoading = false
        } catch let error {
            isLoading = false
            self.errorMessage = AuthError.signOutFailed(error.localizedDescription).localizedDescription
            print("Sign out error: \(error.localizedDescription)")
        }
        isLoading = false // @Published 프로퍼티 업데이트
    }
    
    // 현재 로그인된 사용자가 있는지 확인 (동기적)
    var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    // 현재 로그인된 사용자의 UID 가져오기
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
} 