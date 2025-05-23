import Foundation

// MARK: - WeatherData
struct WeatherData: Codable, Equatable {
    let coord: Coord
    let weather: [Weather]
    let base: String
    let main: Main
    let visibility: Int
    let wind: Wind
    let rain: Rain?
    let clouds: Clouds
    let dt: Int // Unix timestamp
    let sys: Sys
    let timezone: Int
    let id: Int
    let name: String
    let cod: Int
}

// MARK: - Clouds
struct Clouds: Codable, Equatable {
    let all: Int
}

// MARK: - Coord
struct Coord: Codable, Equatable {
    let lon: Double
    let lat: Double
}

// MARK: - Main
struct Main: Codable, Equatable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    let seaLevel: Int?
    let grndLevel: Int?

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
    }
}

// MARK: - Rain
struct Rain: Codable, Equatable {
    let the1H: Double? // "1h"
    let the3H: Double? // "3h"

    enum CodingKeys: String, CodingKey {
        case the1H = "1h"
        case the3H = "3h"
    }
}

// MARK: - Sys
struct Sys: Codable, Equatable {
    let type: Int?
    let id: Int?
    let country: String
    let sunrise: Int // Unix timestamp
    let sunset: Int  // Unix timestamp
}

// MARK: - Weather
struct Weather: Codable, Equatable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

// MARK: - Wind
struct Wind: Codable, Equatable {
    let speed: Double
    let deg: Int
    let gust: Double?
} 