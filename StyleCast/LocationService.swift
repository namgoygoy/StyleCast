import Foundation
import CoreLocation // CoreLocation 프레임워크를 import 합니다.

// 위치 서비스 관련 에러 정의
enum LocationError: Error {
    case authorizationDenied         // 권한 거부됨
    case authorizationRestricted     // 권한 제한됨 (예: 보호자 통제)
    case locationNotFound          // 위치 정보를 찾을 수 없음
    case unknownError              // 알 수 없는 에러
    case clError(Error)            // CLLocationManager 관련 에러
}

// 기본 위치 (서울 시청 좌표) - 위치 정보를 가져올 수 없을 때 사용
struct DefaultLocation {
    static let latitude: CLLocationDegrees = 37.5665
    static let longitude: CLLocationDegrees = 126.9780
    static let location = CLLocation(latitude: latitude, longitude: longitude)
}

// LocationService 클래스 (ObservableObject를 채택하여 SwiftUI 뷰에서 상태 변경을 감지할 수 있도록 함)
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()

    // @Published 어노테이션을 사용하여 SwiftUI 뷰에서 이 프로퍼티들의 변경을 감지
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isLoading: Bool = false // 위치 정보 요청 중인지 여부

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        // locationManager.desiredAccuracy = kCLLocationAccuracyBest // 정확도 설정 (필요에 따라 조절)
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // 날씨 앱이므로 킬로미터 단위 정확도도 충분할 수 있음
    }

    // 위치 정보 접근 권한 요청
    func requestLocationPermission() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // 현재 위치 정보 업데이트 요청
    func requestCurrentLocation() {
        isLoading = true
        // 권한 상태 확인 후 위치 요청
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation() // 단일 위치 업데이트 요청
        case .denied, .restricted:
            print("Location access denied or restricted.")
            // 기본 위치로 설정하거나 사용자에게 알림
            self.currentLocation = DefaultLocation.location
            self.isLoading = false
            // 여기서 사용자에게 권한 설정을 유도하는 알림을 띄울 수 있습니다.
        case .notDetermined:
            print("Location permission not yet determined. Requesting permission.")
            requestLocationPermission()
            // 권한 요청 후, delegate 메소드에서 다시 requestCurrentLocation()을 호출하거나
            // 사용자가 권한을 설정할 때까지 기다려야 할 수 있습니다.
            // 이 예제에서는 일단 isLoading = false로 설정합니다.
            self.isLoading = false 
        @unknown default:
            print("Unknown location authorization status.")
            self.currentLocation = DefaultLocation.location
            self.isLoading = false
        }
    }

    // MARK: - CLLocationManagerDelegate Methods

    // 위치 정보 업데이트 시 호출됨
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoading = false
        if let location = locations.last { // 가장 최신 위치 정보 사용
            self.currentLocation = location
            print("Current location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        } else {
            // 위치를 가져왔지만 데이터가 없는 경우, 기본 위치 사용 또는 에러 처리
            self.currentLocation = DefaultLocation.location
        }
    }

    // 위치 정보 가져오기 실패 시 호출됨
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        self.currentLocation = DefaultLocation.location // 실패 시 기본 위치로 설정
        print("Failed to get location: \(error.localizedDescription)")
        // 여기서 사용자에게 오류를 알릴 수 있습니다.
    }

    // 권한 상태 변경 시 호출됨
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        print("Location authorization status changed: \(authorizationStatus.rawValue)")
        
        // 권한이 허용된 경우, 자동으로 위치 업데이트를 시도할 수 있습니다.
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // 만약 이전에 위치 요청 중이었다면 다시 시도
            // 또는 특정 로직에 따라 위치 요청
             requestCurrentLocation() // 예: 권한 변경 후 바로 위치 요청
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            // 권한이 거부되거나 제한된 경우, 기본 위치로 설정하거나 사용자에게 알림
            self.currentLocation = DefaultLocation.location
            self.isLoading = false
        }
    }
}

// CLAuthorizationStatus를 문자열로 변환하는 extension (디버깅용)
extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized Always"
        case .authorizedWhenInUse: return "Authorized When In Use"
        @unknown default: return "Unknown"
        }
    }
} 