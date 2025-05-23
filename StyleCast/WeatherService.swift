import Foundation

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(String)
}

class WeatherService {
    private let baseURL = "https://api.openweathermap.org/data/2.5/"
    private let apiKey: String
    
    init() {
        // Info.plist에서 API 키 읽기 시도
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenWeatherAPIKey") as? String,
           !apiKey.isEmpty,
           apiKey != "$(OPENWEATHER_API_KEY)" {
            self.apiKey = apiKey
            print("WeatherService initialized with API key from Info.plist: \(apiKey.prefix(8))...")
        } else {
            // Fallback: Config.xcconfig에서 직접 읽기 (개발 환경용)
            print("Info.plist에서 API 키를 찾을 수 없어 Config.xcconfig에서 읽기를 시도합니다.")
            
            guard let configPath = Bundle.main.path(forResource: "Config", ofType: "xcconfig"),
                  let configContent = try? String(contentsOfFile: configPath),
                  let apiKey = Self.extractAPIKey(from: configContent) else {
                // 최후 수단: 하드코딩된 키 사용 (임시)
                print("⚠️ 경고: Config 파일에서 API 키를 찾을 수 없어 기본 키를 사용합니다.")
                self.apiKey = "470a3cf0a1a40f911c97b48675ed559d"
                return
            }
            
            self.apiKey = apiKey
            print("WeatherService initialized with API key from Config.xcconfig: \(apiKey.prefix(8))...")
        }
    }
    
    // Config.xcconfig 파일에서 API 키 추출하는 정적 헬퍼 함수
    private static func extractAPIKey(from configContent: String) -> String? {
        let lines = configContent.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.hasPrefix("OPENWEATHER_API_KEY") && trimmedLine.contains("=") {
                let components = trimmedLine.components(separatedBy: "=")
                if components.count >= 2 {
                    let apiKey = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    return apiKey.isEmpty ? nil : apiKey
                }
            }
        }
        return nil
    }

    // 위도/경도로 현재 날씨 정보 가져오기
    func getCurrentWeatherByLatLon(lat: Double, lon: Double, units: String = "metric") async throws -> WeatherData {
        guard var urlComponents = URLComponents(string: "\(baseURL)weather") else {
            throw NetworkError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lon", value: "\(lon)"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: units),
            URLQueryItem(name: "lang", value: "kr")
        ]

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        return try await fetchData(from: url)
    }

    // 도시 이름으로 현재 날씨 정보 가져오기
    func getCurrentWeatherByCityName(cityName: String, units: String = "metric") async throws -> WeatherData {
        guard var urlComponents = URLComponents(string: "\(baseURL)weather") else {
            throw NetworkError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: cityName),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: units),
            URLQueryItem(name: "lang", value: "kr")
        ]

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        return try await fetchData(from: url)
    }
    
    // 5일/3시간 예보 데이터 가져오기
    func getFiveDayForecastByLatLon(lat: Double, lon: Double, units: String = "metric") async throws -> WeatherForecast {
        guard var urlComponents = URLComponents(string: "\(baseURL)forecast") else {
            throw NetworkError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lon", value: "\(lon)"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: units),
            URLQueryItem(name: "lang", value: "kr")
        ]

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        return try await fetchData(from: url)
    }

    private func fetchData<T: Decodable>(from url: URL) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }
            
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                return decodedData
            } catch {
                // 디코딩 실패 시 에러 내용과 함께 데이터도 출력 (디버깅용)
                print("Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Failed to decode JSON: \(jsonString)")
                }
                throw NetworkError.decodingError(error)
            }
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
} 
