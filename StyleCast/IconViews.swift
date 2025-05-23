import SwiftUI

// OpenWeatherMap API 날씨 아이콘 매핑
struct WeatherIconView: View {
    let iconCode: String
    
    var systemIconName: String {
        // OpenWeatherMap 아이콘 코드에서 마지막 글자(d/n) 제거
        let baseCode = String(iconCode.dropLast())
        
        switch baseCode {
        // 맑음 (Clear sky)
        case "01": 
            return "sun.max.fill"
            
        // 구름 조금 (Few clouds: 11-25%)
        case "02": 
            return "cloud.sun.fill"
            
        // 흩어진 구름 (Scattered clouds: 25-50%)
        case "03": 
            return "cloud.fill"
            
        // 많은 구름 (Broken clouds: 51-84%) / 흐림 (Overcast clouds: 85-100%)
        case "04": 
            return "cloud.fill"
            
        // 소나기 (Shower rain)
        case "09": 
            return "cloud.heavyrain.fill"
            
        // 비 (Rain)
        case "10": 
            return "cloud.rain.fill"
            
        // 뇌우 (Thunderstorm)
        case "11": 
            return "cloud.bolt.rain.fill"
            
        // 눈 (Snow)
        case "13": 
            return "snow"
            
        // 안개/박무 (Mist, Smoke, Haze, Dust, Fog, Sand, Ash, Squall, Tornado)
        case "50": 
            return "cloud.fog.fill"
            
        default: 
            // 알 수 없는 코드의 경우 날씨 설명을 기반으로 추측
            return getIconByDescription()
        }
    }
    
    // 날씨 설명을 기반으로 아이콘 추측 (fallback)
    private func getIconByDescription() -> String {
        let lowercaseCode = iconCode.lowercased()
        
        if lowercaseCode.contains("clear") || lowercaseCode.contains("sunny") {
            return "sun.max.fill"
        } else if lowercaseCode.contains("cloud") {
            return "cloud.fill"
        } else if lowercaseCode.contains("rain") || lowercaseCode.contains("drizzle") {
            return "cloud.rain.fill"
        } else if lowercaseCode.contains("snow") || lowercaseCode.contains("sleet") {
            return "snow"
        } else if lowercaseCode.contains("storm") || lowercaseCode.contains("thunder") {
            return "cloud.bolt.rain.fill"
        } else if lowercaseCode.contains("fog") || lowercaseCode.contains("mist") || lowercaseCode.contains("haze") {
            return "cloud.fog.fill"
        } else {
            return "cloud.fill" // 기본값: 구름
        }
    }
    
    // 밤낮 구분 아이콘
    var nightAdjustedIconName: String {
        let baseIcon = systemIconName
        let isNight = iconCode.hasSuffix("n")
        
        if isNight {
            switch baseIcon {
            case "sun.max.fill":
                return "moon.stars.fill"
            case "cloud.sun.fill":
                return "cloud.moon.fill"
            case "cloud.rain.fill":
                return iconCode == "10n" ? "cloud.moon.rain.fill" : "cloud.rain.fill"
            case "cloud.heavyrain.fill":
                return "cloud.rain.fill"
            default:
                return baseIcon
            }
        }
        
        return baseIcon
    }
    
    // 날씨 상태에 따른 색상
    var iconColor: Color {
        let baseCode = String(iconCode.dropLast())
        let isNight = iconCode.hasSuffix("n")
        
        switch baseCode {
        case "01": // 맑음
            return isNight ? .yellow : .orange
        case "02": // 구름 조금
            return isNight ? .gray : .blue
        case "03", "04": // 구름
            return .gray
        case "09", "10": // 비
            return .blue
        case "11": // 뇌우
            return .purple
        case "13": // 눈
            return .cyan
        case "50": // 안개
            return .gray
        default:
            return .primary
        }
    }

    var body: some View {
        Image(systemName: nightAdjustedIconName)
            .foregroundColor(iconColor)
            .symbolRenderingMode(.hierarchical)
    }
} 