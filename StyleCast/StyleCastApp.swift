//
//  StyleCastApp.swift
//  StyleCast
//
//  Created by lee on 5/23/25.
//

import SwiftUI
import FirebaseCore

@main
struct StyleCastApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var mainViewModel: MainViewModel
    
    init() {
        FirebaseApp.configure()
        
        // 서비스 인스턴스들 생성
        let weatherService = WeatherService()
        let locationService = LocationService()
        let firestoreService = FirestoreService()
        
        // 임시 AuthService 생성 (초기화 시에만 필요)
        // 나중에 onAppear에서 실제 authService로 교체됨
        let tempAuthService = AuthService()
        
        // MainViewModel 생성 및 의존성 주입
        _mainViewModel = StateObject(wrappedValue: MainViewModel(
            weatherService: weatherService,
            locationService: locationService,
            authService: tempAuthService,
            firestoreService: firestoreService
        ))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.user != nil {
                    MainTabView()
                        .environmentObject(authService)
                        .environmentObject(mainViewModel)
                        .onAppear {
                            // 실제 authService로 교체
                            mainViewModel.setAuthService(authService)
                        }
                } else {
                    LoginView()
                        .environmentObject(authService)
                }
            }
            .onAppear {
                print("Current auth status: \(authService.isSignedIn)")
            }
        }
    }
}
