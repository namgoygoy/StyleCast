import Foundation
import Combine
import CoreLocation // CLLocationCoordinate2D 사용을 위해

@MainActor // UI 업데이트는 메인 스레드에서
class MainViewModel: ObservableObject {
    // 서비스 의존성 (초기화 시 주입받거나 싱글톤 사용)
    private let weatherService: WeatherService
    private let locationService: LocationService // 위치 정보 가져오기용
    private var authService: AuthService // 사용자 정보 (닉네임 등) 접근용 - var로 변경하여 교체 가능
    private let firestoreService: FirestoreService // 닉네임 가져오기용

    // UI에 바인딩될 Published 프로퍼티들
    @Published var currentWeatherData: WeatherData?
    @Published var recommendedOutfits: [OutfitItem] = []
    @Published var isLoadingWeather: Bool = false
    @Published var weatherErrorMessage: String?
    
    @Published var selectedGender: Gender = .men { // 기본값 남성
        didSet {
            updateOutfitRecommendations() // 성별 변경 시 옷차림 다시 추천
        }
    }
    @Published var selectedStyle: Style = .street { // 기본값 스트릿
        didSet {
            updateOutfitRecommendations() // 스타일 변경 시 옷차림 다시 추천
        }
    }
    @Published var searchCityName: String = ""
    @Published var userWelcomeMessage: String = "환영합니다!"

    // 위치 서비스의 현재 위치를 구독하기 위한 Cancellable
    private var locationCancellable: AnyCancellable?
    private var authCancellable: AnyCancellable?

    init(weatherService: WeatherService, locationService: LocationService, authService: AuthService, firestoreService: FirestoreService) {
        self.weatherService = weatherService
        self.locationService = locationService
        self.authService = authService
        self.firestoreService = firestoreService
        
        // 위치 서비스의 현재 위치 변경을 구독
        subscribeToLocationUpdates()
        // 인증 서비스의 사용자 변경을 구독 (닉네임 업데이트 등)
        subscribeToAuthUpdates()
        
        // 초기 환영 메시지 설정 (필요시)
        Task {
           await loadUserWelcomeMessage()
        }
    }
    
    // AuthService 인스턴스를 교체하는 메서드
    func setAuthService(_ newAuthService: AuthService) {
        self.authService = newAuthService
        // 구독을 다시 설정
        subscribeToAuthUpdates()
        // 사용자 정보를 다시 로드
        Task {
            await loadUserWelcomeMessage()
        }
    }

    private func subscribeToLocationUpdates() {
        locationCancellable = locationService.$currentLocation
            .debounce(for: .seconds(1), scheduler: RunLoop.main) // 약간의 디바운싱
            .sink { [weak self] location in
                guard let self = self, let loc = location else { return }
                // 위치가 변경되면 해당 위치의 날씨를 가져옴 (자동 새로고침)
                // 단, 사용자가 도시를 검색한 경우에는 이 로직을 건너뛸 수 있도록 플래그 관리 필요
                print("Location updated in ViewModel: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
                Task {
                    await self.fetchWeatherByCoordinates(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
                }
            }
    }
    
    private func subscribeToAuthUpdates() {
        authCancellable = authService.$user
            .sink { [weak self] firebaseUser in
                Task {
                    await self?.loadUserWelcomeMessage()
                }
            }
    }

    func loadInitialData() {
        // 앱 시작 시 또는 화면 나타날 때 호출
        // 1. 위치 권한 요청 (LocationService에서 처리)
        locationService.requestLocationPermission()
        // 2. 현재 위치 기반 날씨 가져오기 (권한 상태에 따라 LocationService가 처리)
        //    LocationService의 authorizationStatus를 보고, 허용 상태면 위치 요청
        if locationService.authorizationStatus == .authorizedWhenInUse || locationService.authorizationStatus == .authorizedAlways {
            locationService.requestCurrentLocation() // 위치 업데이트 요청 -> sink에서 날씨 가져옴
        } else if locationService.authorizationStatus == .notDetermined {
            // 권한 요청중, locationManagerDidChangeAuthorization 에서 처리될 것임
        }
        else {
            // 권한 없거나 거부됨 -> 기본 위치(서울) 날씨 가져오기
            Task {
                await fetchWeatherByCoordinates(latitude: DefaultLocation.latitude, longitude: DefaultLocation.longitude, isDefault: true)
            }
        }
        Task {
            await loadUserWelcomeMessage()
        }
    }
    
    func loadUserWelcomeMessage() async {
        if authService.user?.isAnonymous == true {
            self.userWelcomeMessage = "환영합니다, 게스트님!"
            return
        }
        
        guard let userId = authService.currentUserId, let email = authService.user?.email else {
            self.userWelcomeMessage = "환영합니다!"
            return
        }
        
        do {
            if let nickname = try await firestoreService.fetchUserNickname(uid: userId) {
                self.userWelcomeMessage = "환영합니다, \(nickname)님!"
            } else {
                self.userWelcomeMessage = "환영합니다, \(email)님!"
            }
        } catch {
            print("Error fetching nickname: \(error.localizedDescription)")
            self.userWelcomeMessage = "환영합니다, \(email)님!" // 오류 시 이메일로 표시
        }
    }

    // 좌표로 날씨 정보 가져오기
    func fetchWeatherByCoordinates(latitude: Double, longitude: Double, isDefault: Bool = false) async {
        isLoadingWeather = true
        weatherErrorMessage = nil
        do {
            let weatherData = try await weatherService.getCurrentWeatherByLatLon(lat: latitude, lon: longitude)
            self.currentWeatherData = weatherData
            updateOutfitRecommendations() // 날씨 정보 업데이트 후 옷차림 추천
            if isDefault {
                // 위치 권한 없을 때 기본 위치 날씨 가져왔음을 알림 (Toast 메시지 등)
                // self.weatherErrorMessage = "위치 권한이 없어 기본 지역의 날씨를 표시합니다." (Toast로 표시하는게 더 나음)
                print("Fetched weather for default location as permission was not granted.")
            }
        } catch let error as NetworkError {
            self.weatherErrorMessage = error.localizedDescription
            print("NetworkError fetching weather: \(error.localizedDescription)")
        } catch {
            self.weatherErrorMessage = "알 수 없는 오류로 날씨 정보를 가져오지 못했습니다."
            print("Unknown error fetching weather: \(error.localizedDescription)")
        }
        isLoadingWeather = false
    }

    // 도시 이름으로 날씨 검색
    func fetchWeatherByCityName() async {
        guard !searchCityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            weatherErrorMessage = "도시 이름을 입력해주세요."
            return
        }
        isLoadingWeather = true
        weatherErrorMessage = nil
        do {
            let weatherData = try await weatherService.getCurrentWeatherByCityName(cityName: searchCityName)
            self.currentWeatherData = weatherData
            updateOutfitRecommendations()
            // self.searchCityName = "" // 검색 후 입력 필드 초기화 (View에서 처리 가능)
        } catch let error as NetworkError {
            self.weatherErrorMessage = error.localizedDescription
            print("NetworkError fetching weather by city: \(error.localizedDescription)")
        } catch {
            self.weatherErrorMessage = "도시를 찾을 수 없습니다."
            print("Unknown error fetching weather by city: \(error.localizedDescription)")
        }
        isLoadingWeather = false
    }

    // 옷차림 추천 목록 업데이트
    // 안드로이드: updateFashionRecommendation, loadOutfitImages
    private func updateOutfitRecommendations() {
        guard let temp = currentWeatherData?.main.temp else {
            recommendedOutfits = []
            return
        }

        let tempCategory = TemperatureCategory.from(temperature: temp)
        let genderFolder = selectedGender.folderName // "men" 또는 "women"
        let tempFolder = tempCategory.folderName

        var outfits: [OutfitItem] = []
        let numberOfStyles = 5 // 각 카테고리별 스타일 개수

        for i in 1...numberOfStyles {
            // 새로운 통일된 이미지 이름 생성 (모든 이미지가 복수형 사용)
            let imageName: String
            
            if selectedStyle == .minimal {
                // 미니멀 스타일: "성별_온도카테고리_minimal_번호" (예: "men_cold_minimal_1")
                imageName = "\(genderFolder)_\(tempFolder)_minimal_\(i)"
            } else {
                // 스트릿(기본) 스타일: "성별_온도카테고리_번호" (예: "men_cold_1")
                imageName = "\(genderFolder)_\(tempFolder)_\(i)"
            }
            
            // 스타일 설명
            let styleDescription: String
            switch i {
            case 1: styleDescription = "베이직 룩"
            case 2: styleDescription = "캐주얼 룩"
            case 3: styleDescription = "스포티 룩"
            case 4: styleDescription = "클래식 룩"
            case 5: styleDescription = "데일리 룩"
            default: styleDescription = "추천 스타일 \(i)"
            }
            
            outfits.append(OutfitItem(
                imageName: imageName,
                title: "\(selectedStyle.rawValue) \(styleDescription)",
                description: "\(tempCategory.rawValue) • \(selectedGender.rawValue)"
            ))
        }
        self.recommendedOutfits = outfits
    }
    
    // 새로고침 기능
    func refreshWeatherData() {
        // 현재 위치 정보가 있다면 그것으로, 없다면 마지막으로 성공한 도시나 기본 위치로.
        if let currentLoc = locationService.currentLocation,
           (locationService.authorizationStatus == .authorizedWhenInUse || locationService.authorizationStatus == .authorizedAlways) {
            Task {
                await fetchWeatherByCoordinates(latitude: currentLoc.coordinate.latitude, longitude: currentLoc.coordinate.longitude)
            }
        } else if let lastCity = currentWeatherData?.name, !lastCity.isEmpty { // 마지막으로 검색한 도시 이름이 있다면
            searchCityName = lastCity // 검색창에 다시 채우고
            Task {
                await fetchWeatherByCityName() // 해당 도시로 재검색
            }
        }
        else { // 그것도 없다면 기본 위치 (서울)
            Task {
                await fetchWeatherByCoordinates(latitude: DefaultLocation.latitude, longitude: DefaultLocation.longitude, isDefault: true)
            }
        }
    }
} 