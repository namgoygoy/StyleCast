import Foundation

// MARK: - WeatherForecast
struct WeatherForecast: Codable {
    let cod: String
    let message: Double // In the Android model it's Double, but usually it's Int or String. Verify API.
    let cnt: Int
    let list: [ForecastItemData]
}

// MARK: - ForecastItemData (was WeekendWeatherData)
struct ForecastItemData: Codable {
    let dt: Int // Unix timestamp
    let main: ForecastMainData
    let weather: [ForecastWeatherDetail] // Reusing Weather struct from above might be possible if identical
    let clouds: ForecastCloudsData       // Reusing Clouds struct from above might be possible if identical
    let wind: ForecastWindData         // Reusing Wind struct from above might be possible if fields match type
    let visibility: Int // In Android model it was Double, typically Int for visibility in meters. Verify API.
    let pop: Double // Probability of precipitation
    let sys: ForecastSysData
    let dtTxt: String

    enum CodingKeys: String, CodingKey {
        case dt, main, weather, clouds, wind, visibility, pop, sys
        case dtTxt = "dt_txt"
    }
}

// MARK: - ForecastMainData
struct ForecastMainData: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let seaLevel: Int
    let grndLevel: Int
    let humidity: Int
    let tempKf: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
        case humidity
        case tempKf = "temp_kf"
    }
}

// MARK: - ForecastWeatherDetail (can be aliased or replaced by Weather if identical)
struct ForecastWeatherDetail: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

// MARK: - ForecastCloudsData (can be aliased or replaced by Clouds if identical)
struct ForecastCloudsData: Codable {
    let all: Int
}

// MARK: - ForecastWindData
struct ForecastWindData: Codable {
    let speed: Double
    let deg: Double // Note: In WeatherData.Wind, deg is Int. Here it's Double.
    let gust: Double? // In Android version, gust was Double. Make it optional if not always present.
}

// MARK: - ForecastSysData
struct ForecastSysData: Codable {
    let pod: String // Part of day (d or n)
} 