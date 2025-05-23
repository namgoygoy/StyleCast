import SwiftUI
import CoreLocation

// 탭 간 데이터 공유를 위한 Observable 클래스
class TabCoordinator: ObservableObject {
    @Published var weatherCoordinates = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 기본 서울 좌표
    
    func updateWeatherCoordinates(_ coordinates: CLLocationCoordinate2D) {
        weatherCoordinates = coordinates
    }
}

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var tabCoordinator = TabCoordinator()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈 탭
            NavigationView {
                MainView()
                    .environmentObject(authService)
                    .environmentObject(tabCoordinator)
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                Text("홈")
            }
            .tag(0)
            
            // 날씨 탭
            NavigationView {
                WeatherDetailView(coordinates: tabCoordinator.weatherCoordinates)
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "cloud.sun.fill" : "cloud.sun")
                Text("날씨")
            }
            .tag(1)
            
            // 프로필 탭
            NavigationView {
                ProfileView()
                    .environmentObject(authService)
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                Text("프로필")
            }
            .tag(2)
        }
        .accentColor(.blue)
    }
} 