import SwiftUI
import Charts // iOS 16+
import CoreLocation // CLLocationCoordinate2D 사용을 위해 추가

struct WeatherDetailView: View {
    // ViewModel은 이전 뷰에서 전달받거나 EnvironmentObject로 주입
    @StateObject private var viewModel: WeatherDetailViewModel
    
    // 표시할 위치의 좌표 (예시: MainView에서 전달받음)
    private var coordinates: CLLocationCoordinate2D 

    init(coordinates: CLLocationCoordinate2D) {
        self.coordinates = coordinates
        // ViewModel 초기화 시 WeatherService 인스턴스 필요
        // 실제 앱에서는 WeatherService를 싱글톤이나 의존성 주입으로 관리
        let weatherService = WeatherService() // API 키는 WeatherService 내부에서 관리
        _viewModel = StateObject(wrappedValue: WeatherDetailViewModel(weatherService: weatherService, coordinates: coordinates))
    }
    
    // 만약 ViewModel을 외부에서 주입받는다면:
    // init(viewModel: WeatherDetailViewModel, coordinates: CLLocationCoordinate2D) {
    //     _viewModel = StateObject(wrappedValue: viewModel)
    //     self.coordinates = coordinates
    // }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("상세 날씨 로딩 중...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // 1. 현재 날씨 요약 (상단)
                    if let currentWeather = viewModel.currentWeatherData {
                        CurrentWeatherSummaryView(weather: currentWeather)
                            .padding(.horizontal)
                    }

                    // 2. 시간별 온도 그래프 (Swift Charts - iOS 16+)
                    if !viewModel.hourlyForecast.isEmpty {
                        if #available(iOS 16.0, *) {
                            HourlyForecastChartView(hourlyForecast: viewModel.hourlyForecast)
                                .padding(.horizontal)
                        } else {
                            Text("시간별 예보 그래프는 iOS 16 이상에서 지원됩니다.")
                                .padding()
                        }
                    } else if viewModel.currentWeatherData != nil { // 날씨는 로드됐지만 시간별 예보가 없을 때
                        Text("시간별 예보 정보가 없습니다.")
                            .padding()
                    }
                    
                    Divider().padding(.horizontal)

                    // 3. 주간 예보 리스트
                    if !viewModel.dailyForecast.isEmpty {
                        DailyForecastListView(dailyForecast: viewModel.dailyForecast)
                            .padding(.horizontal)
                    } else if viewModel.currentWeatherData != nil {
                        Text("주간 예보 정보가 없습니다.")
                            .padding()
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(viewModel.currentWeatherData?.name ?? "날씨 상세")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                // 화면 나타날 때 해당 좌표의 날씨 정보 로드
                await viewModel.loadWeatherData(latitude: coordinates.latitude, longitude: coordinates.longitude)
            }
        }
    }
}

// --- 서브 뷰들 ---

struct CurrentWeatherSummaryView: View {
    let weather: WeatherData
    private let MddEFormatter: DateFormatter = { // 안드로이드의 dateFormat
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("오늘 (\(MddEFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(weather.dt))))) ")
                .font(.title2)
                .bold()
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Int(round(weather.main.temp)))°")
                        .font(.system(size: 70, weight: .thin))
                    Text(weather.weather.first?.description ?? "")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    WeatherIconView(iconCode: weather.weather.first?.icon ?? "01d")
                        .font(.system(size: 80))
                        .foregroundColor(.primary)
                    Text(weather.weather.first?.main ?? "흐림")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("최고: \(Int(round(weather.main.tempMax)))° / 최저: \(Int(round(weather.main.tempMin)))°")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

@available(iOS 16.0, *)
struct HourlyForecastChartView: View {
    let hourlyForecast: [HourlyForecastItem]
    private let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("시간별 예보")
                .font(.title3).bold()
                .padding(.horizontal)
            
            Chart {
                ForEach(hourlyForecast) { item in
                    // 선 그래프
                    LineMark(
                        x: .value("시간", item.time, unit: .hour),
                        y: .value("온도", item.temperature)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)

                    // 각 포인트에 아이콘과 온도 표시
                    PointMark(
                         x: .value("시간", item.time, unit: .hour),
                         y: .value("온도", item.temperature)
                    )
                    .foregroundStyle(Color.blue)
                    .annotation(position: .top, alignment: .center) {
                        VStack(spacing: 2) {
                            WeatherIconView(iconCode: item.iconCode)
                                .font(.caption)
                            Text("\(Int(round(item.temperature)))°")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                    AxisGridLine()
                    AxisTick()
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(hourFormatter.string(from: date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(dash: [2,3]))
                    AxisTick()
                    if let temp = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(round(temp)))°")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
    }
}

struct DailyForecastListView: View {
    let dailyForecast: [DailyForecastItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("주간 예보")
                .font(.title3).bold()
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(dailyForecast) { item in
                    HStack(alignment: .center, spacing: 16) {
                        // 날짜
                        Text(item.MddEdate)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 60, alignment: .leading)
                        
                        // 강수확률 (10% 초과 시만 표시)
                        if let rainProb = item.rainProbability, rainProb > 10 {
                            Text("\(rainProb)%")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .frame(width: 40, alignment: .center)
                        } else {
                            Spacer()
                                .frame(width: 40)
                        }
                        
                        Spacer()
                        
                        // 날씨 아이콘
                        WeatherIconView(iconCode: item.weatherIconCode)
                            .font(.title3)
                            .frame(width: 40, alignment: .center)
                        
                        Spacer()
                        
                        // 최저 온도
                        Text("\(Int(round(item.minTemp)))°")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .trailing)
                        
                        // 최고 온도
                        Text("\(Int(round(item.maxTemp)))°")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 35, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    if item.id != dailyForecast.last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
}

// Preview (예시 - 실제 좌표와 서비스 필요)
// struct WeatherDetailView_Previews: PreviewProvider {
//     static var previews: some View {
//         NavigationView {
//             WeatherDetailView(coordinates: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780))
//         }
//     }
// } 