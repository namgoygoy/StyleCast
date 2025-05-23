import Foundation
import Combine
import CoreLocation // 현재 위치 또는 특정 위치의 날씨를 가져올 경우 필요

@MainActor
class WeatherDetailViewModel: ObservableObject {
    private let weatherService: WeatherService
    // 특정 위치의 날씨를 표시하거나, 사용자의 현재 위치를 받을 수 있음
    private var currentLocation: CLLocationCoordinate2D?

    @Published var currentWeatherData: WeatherData? // 현재 날씨 요약 (상단 표시용)
    @Published var hourlyForecast: [HourlyForecastItem] = [] // 시간별 예보 (그래프용)
    @Published var dailyForecast: [DailyForecastItem] = []   // 주간 예보 (리스트용)
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // 날짜 포맷터
    private let MddEFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    private let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "H시" // 또는 "HH:00"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()


    // 초기화 시 WeatherService와 표시할 위치의 좌표를 받음
    init(weatherService: WeatherService, coordinates: CLLocationCoordinate2D? = nil) {
        self.weatherService = weatherService
        self.currentLocation = coordinates
        // 만약 coordinates가 nil이면, LocationService를 통해 현재 위치를 받아오도록 확장 가능
    }

    func loadWeatherData(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        
        currentLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        async let currentWeatherTask = weatherService.getCurrentWeatherByLatLon(lat: latitude, lon: longitude)
        async let forecastTask = weatherService.getFiveDayForecastByLatLon(lat: latitude, lon: longitude)

        do {
            let (current, forecast) = try await (currentWeatherTask, forecastTask)
            self.currentWeatherData = current
            processForecastData(forecast) // 예보 데이터 가공
            
        } catch let error as NetworkError {
            self.errorMessage = "날씨 정보 로드 실패: \(error.localizedDescription)"
            print("NetworkError fetching weather details: \(error)")
        } catch {
            self.errorMessage = "알 수 없는 오류로 날씨 정보를 가져오지 못했습니다."
            print("Unknown error fetching weather details: \(error)")
        }
        isLoading = false
    }
    
    // 5일/3시간 예보 데이터를 가공하여 시간별/일별 예보로 변환
    private func processForecastData(_ forecastData: WeatherForecast) {
        // 시간별 예보 (예: 다음 24시간 또는 8개 항목)
        var hourlyItems: [HourlyForecastItem] = []
        let upcomingForecasts = forecastData.list.prefix(8) // 예시로 8개 (24시간)
        
        for itemData in upcomingForecasts {
            hourlyItems.append(HourlyForecastItem(
                time: Date(timeIntervalSince1970: TimeInterval(itemData.dt)),
                temperature: itemData.main.temp,
                iconCode: itemData.weather.first?.icon ?? "01d"
            ))
        }
        self.hourlyForecast = hourlyItems

        // 일별 예보 (5일치)
        // 3시간 간격 데이터를 일별로 그룹화하고, 최고/최저 온도, 주요 날씨 아이콘 등을 계산
        var dailyItems: [DailyForecastItem] = []
        let calendar = Calendar.current
        
        // dt를 기준으로 날짜별 그룹핑
        let groupedByDay = Dictionary(grouping: forecastData.list) { item -> DateComponents in
            calendar.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: TimeInterval(item.dt)))
        }
        
        // 정렬된 날짜 키
        let sortedDays = groupedByDay.keys.sorted {
            guard let date1 = calendar.date(from: $0), let date2 = calendar.date(from: $1) else { return false }
            return date1 < date2
        }

        for dayComponents in sortedDays {
            guard let date = calendar.date(from: dayComponents),
                  let itemsForDay = groupedByDay[dayComponents],
                  !itemsForDay.isEmpty else { continue }

            let minTemp = itemsForDay.map { $0.main.tempMin }.min() ?? 0
            let maxTemp = itemsForDay.map { $0.main.tempMax }.max() ?? 0
            // 하루 중 가장 자주 나오는 날씨 아이콘 또는 특정 시간대(예: 낮) 아이콘 선택
            let representativeWeather = itemsForDay.first // 간단하게 첫번째 아이템의 날씨 사용 (개선 필요)
            let rainProb = itemsForDay.map { $0.pop * 100 }.max() // 하루 중 최대 강수확률

            dailyItems.append(DailyForecastItem(
                date: date,
                MddEdate: MddEFormatter.string(from: date),
                weatherIconCode: representativeWeather?.weather.first?.icon ?? "01d",
                rainProbability: Int(round(rainProb ?? 0)),
                minTemp: minTemp,
                maxTemp: maxTemp
            ))
            
            if dailyItems.count >= 5 { break } // 최대 5일치만 표시
        }
        self.dailyForecast = dailyItems
    }
    
    // 시간 포맷팅 헬퍼
    func formatHour(from date: Date) -> String {
        return hourFormatter.string(from: date)
    }
} 