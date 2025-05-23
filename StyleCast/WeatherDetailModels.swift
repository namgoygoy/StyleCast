import Foundation

// 시간별 예보 아이템 (그래프 및 리스트용)
struct HourlyForecastItem: Identifiable {
    let id = UUID()
    let time: Date // 시간
    let temperature: Double
    let iconCode: String // 날씨 아이콘 코드 (예: "01d")
}

// 주간 예보 아이템 (리스트용 - 안드로이드의 WeeklyForecastItem과 유사)
struct DailyForecastItem: Identifiable {
    let id = UUID()
    let date: Date
    let MddEdate: String // "M.d (E)" 형식의 날짜 문자열 (안드로이드의 dateFormat)
    let weatherIconCode: String // 날씨 아이콘 코드
    let rainProbability: Int? // 강수 확률 (OpenWeatherMap 5일 예보에는 pop으로 제공됨)
    let minTemp: Double
    let maxTemp: Double
} 