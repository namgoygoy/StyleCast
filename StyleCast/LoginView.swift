import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService // AuthService를 EnvironmentObject로 주입받음
    
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView { // 네비게이션 스택 사용
            VStack(spacing: 20) {
                Text("로그인")
                    .font(.largeTitle)
                    .padding(.bottom, 30)

                TextField("이메일", text: $email)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)

                SecureField("비밀번호", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    Task {
                        await authService.signIn(email: email, password: password)
                        // 로그인 성공 시 authService.user가 업데이트되고,
                        // 이를 감지하여 메인 화면으로 전환하는 로직이 필요 (예: App 구조체 또는 SceneDelegate)
                    }
                }) {
                    Text("로그인")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                
                if authService.isLoading {
                    ProgressView()
                }

                HStack {
                    Text("계정이 없으신가요?")
                    NavigationLink("회원가입", destination: SignUpView())
                }
                .padding(.top)
                
                Button("게스트로 계속하기") {
                    Task {
                        await authService.signInAnonymously()
                    }
                }
                .padding(.top)

            }
            .padding()
            // .navigationTitle("로그인") // 네비게이션 바 타이틀
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode // 화면 닫기용
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var nickname = "" // 닉네임 필드 추가

    var body: some View {
        VStack(spacing: 20) {
            Text("회원가입")
                .font(.largeTitle)
                .padding(.bottom, 30)

            TextField("이메일", text: $email)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)

            SecureField("비밀번호 (6자 이상)", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("비밀번호 확인", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("닉네임", text: $nickname) // 닉네임 입력
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // 비밀번호 일치 여부 간단히 확인 (실제로는 더 견고한 유효성 검사 필요)
            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                Text("비밀번호가 일치하지 않습니다.")
                    .foregroundColor(.red)
                    .font(.caption)
            }


            Button(action: {
                // 입력값 유효성 검사 (예: 빈 값, 비밀번호 일치, 비밀번호 길이 등)
                guard !email.isEmpty, !password.isEmpty, !nickname.isEmpty else {
                    authService.errorMessage = "모든 필드를 입력해주세요."
                    return
                }
                guard password == confirmPassword else {
                    authService.errorMessage = "비밀번호가 일치하지 않습니다."
                    return
                }
                guard password.count >= 6 else {
                    authService.errorMessage = "비밀번호는 6자 이상이어야 합니다."
                    return
                }
                
                Task {
                    await authService.signUp(email: email, password: password, nickname: nickname)
                    if authService.user != nil { // 회원가입 성공 시
                        presentationMode.wrappedValue.dismiss() // 이전 화면(로그인)으로 돌아가기
                    }
                }
            }) {
                Text("회원가입")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(authService.isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || nickname.isEmpty || password != confirmPassword)

            if authService.isLoading {
                ProgressView()
            }
        }
        .padding()
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            authService.errorMessage = nil // 화면 나타날 때 에러 메시지 초기화
        }
    }
} 