import SwiftUI
import CoreLocation

struct MainView: View {
    // ViewModel을 EnvironmentObject로 주입받도록 변경
    @EnvironmentObject var viewModel: MainViewModel
    
    // AuthService는 EnvironmentObject로 주입받는다고 가정 (로그아웃, 프로필 이동 등)
    @EnvironmentObject var authService: AuthService
    
    // 탭 간 데이터 공유를 위한 TabCoordinator
    @EnvironmentObject var tabCoordinator: TabCoordinator
    
    // 다른 화면으로 이동하기 위한 상태 변수 (예시)
    @State private var navigateToProfile = false
    
    // 스타일 상세 화면 네비게이션을 위한 상태 변수
    @State private var selectedStyleData: StyleDetailData?
    @State private var navigateToStyleDetail = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 상단 사용자 정보 및 프로필 이동 버튼
                HStack {
                    Text(viewModel.userWelcomeMessage)
                        .font(.headline)
                    Spacer()
                    Button {
                        navigateToProfile = true // 프로필 화면으로 이동 (네비게이션 로직 필요)
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                    .background(
                        NavigationLink(destination: ProfileView(), isActive: $navigateToProfile) { EmptyView() }
                    )
                }
                .padding()

                // 도시 검색 바
                HStack {
                    TextField("도시 이름 검색 (예: Seoul)", text: $viewModel.searchCityName, onCommit: {
                        Task {
                            await viewModel.fetchWeatherByCityName()
                        }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button {
                        Task {
                            await viewModel.fetchWeatherByCityName()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .padding(.horizontal)

                // 현재 날씨 정보 표시
                if viewModel.isLoadingWeather {
                    ProgressView("날씨 정보 로딩 중...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let weather = viewModel.currentWeatherData {
                    WeatherInfoView(weather: weather) // 날씨 정보 표시를 위한 서브 뷰
                        .padding(.vertical)
                } else if let errorMessage = viewModel.weatherErrorMessage {
                    Text("오류: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    Text("날씨 정보를 가져오려면 도시를 검색하거나 위치 권한을 허용해주세요.")
                        .padding()
                }
                
                Divider()

                // 성별 및 스타일 선택 - Chip 스타일
                VStack(alignment: .leading, spacing: 12) {
                    // 성별 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("성별")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            ForEach(Gender.allCases) { gender in
                                ChipButton(
                                    title: gender.rawValue,
                                    icon: gender.systemIcon,
                                    isSelected: viewModel.selectedGender == gender
                                ) {
                                    viewModel.selectedGender = gender
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // 스타일 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("스타일")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            ForEach(Style.allCases) { style in
                                ChipButton(
                                    title: style.rawValue,
                                    icon: style.systemIcon,
                                    isSelected: viewModel.selectedStyle == style
                                ) {
                                    viewModel.selectedStyle = style
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)

                // 옷차림 추천 목록
                Text("오늘의 추천 옷차림")
                    .font(.title2)
                    .padding(.horizontal)
                
                if viewModel.recommendedOutfits.isEmpty && viewModel.currentWeatherData != nil && !viewModel.isLoadingWeather {
                    Text("추천 옷차림을 준비 중이거나, 해당 조건의 이미지가 없습니다.")
                        .foregroundColor(.gray)
                        .padding()
                } else if !viewModel.recommendedOutfits.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.recommendedOutfits) { outfit in
                                OutfitCardView(outfit: outfit, onTap: {
                                    // 옷차림 상세 화면으로 이동하는 로직
                                    let styleItems = createStyleItems(for: outfit) // 헬퍼 함수
                                    let styleDetailData = StyleDetailData(
                                        outfitTitle: outfit.title,
                                        heading: "Dress to impress",
                                        description: outfit.description,
                                        items: styleItems
                                    )
                                    selectedStyleData = styleDetailData
                                    navigateToStyleDetail = true
                                })
                            }
                        }
                        .padding()
                    }
                } else if viewModel.currentWeatherData == nil && !viewModel.isLoadingWeather {
                     Text("날씨 정보가 없어 옷차림을 추천할 수 없습니다.")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                // 하단 여백 추가 (ScrollView에서 마지막 컨텐츠가 잘리지 않도록)
                Color.clear
                    .frame(height: 50)
            }
        }
        .navigationBarTitle("오늘의 날씨 옷차림", displayMode: .inline)
        .navigationBarItems(trailing: Button {
            viewModel.refreshWeatherData()
        } label: {
            Image(systemName: "arrow.clockwise")
        })
        .background(
            NavigationLink(
                destination: selectedStyleData.map { styleData in
                    StyleDetailView(
                        styleData: styleData,
                        firestoreService: FirestoreService(),
                        authService: authService
                    )
                },
                isActive: $navigateToStyleDetail
            ) { EmptyView() }
        )
        .onAppear {
            viewModel.loadInitialData()
        }
        .onChange(of: viewModel.currentWeatherData) { weatherData in
            if let weather = weatherData {
                let newCoordinates = CLLocationCoordinate2D(
                    latitude: weather.coord.lat,
                    longitude: weather.coord.lon
                )
                tabCoordinator.updateWeatherCoordinates(newCoordinates)
            }
        }
        // MainView는 보통 TabView의 일부가 될 것이므로, 탭바는 여기서 직접 구현하지 않음
        // .environmentObject(AuthService()) // Preview 또는 App 구조체에서 주입
    }
    
    // 헬퍼 함수: OutfitItem을 기반으로 StyleItem 배열 생성
    private func createStyleItems(for outfit: OutfitItem) -> [StyleItem] {
        // 실제로는 데이터베이스나 API에서 가져올 수 있음
        // 여기서는 outfit의 특성에 따라 다른 아이템을 반환하도록 개선
        
        // 기본 아이템들 (실제로는 outfit.imageName이나 outfit.title을 기반으로 적절한 아이템들을 생성)
        var items: [StyleItem] = []
        
        // outfit.title이나 imageName에 따라 다른 스타일 아이템 조합을 생성
        if outfit.title.contains("추위") || outfit.title.contains("겨울") || outfit.imageName.contains("cold") {
            // 추운 날씨용 아이템
            items = [
                StyleItem(name: "코트", imageName: "cardigan", price: "$120", shopURL: "https://www.musinsa.com/products/4646174"),
                StyleItem(name: "스웨터", imageName: "t-shirt", price: "$65", shopURL: "https://www.musinsa.com/products/3525289"),
                StyleItem(name: "청바지", imageName: "pants", price: "$80", shopURL: "https://www.musinsa.com/products/4743479"),
                StyleItem(name: "부츠", imageName: "shoes", price: "$150", shopURL: "https://www.musinsa.com/products/3374068")
            ]
        } else if outfit.title.contains("더위") || outfit.title.contains("여름") || outfit.imageName.contains("hot") {
            // 더운 날씨용 아이템
            items = [
                StyleItem(name: "반팔 티셔츠", imageName: "t-shirt", price: "$25", shopURL: "https://www.musinsa.com/products/4646174"),
                StyleItem(name: "반바지", imageName: "pants", price: "$35", shopURL: "https://www.musinsa.com/products/3525289"),
                StyleItem(name: "선글라스", imageName: "cardigan", price: "$45", shopURL: "https://www.musinsa.com/products/4743479"),
                StyleItem(name: "샌들", imageName: "shoes", price: "$60", shopURL: "https://www.musinsa.com/products/3374068")
            ]
        } else {
            // 기본/봄가을용 아이템
            items = [
                StyleItem(name: "가디건", imageName: "cardigan", price: "$59", shopURL: "https://www.musinsa.com/products/4646174"),
                StyleItem(name: "팬츠", imageName: "pants", price: "$39", shopURL: "https://www.musinsa.com/products/3525289"),
                StyleItem(name: "운동화", imageName: "shoes", price: "$89", shopURL: "https://www.musinsa.com/products/4743479"),
                StyleItem(name: "셔츠", imageName: "t-shirt", price: "$29", shopURL: "https://www.musinsa.com/products/3374068")
            ]
        }
        
        return items
    }
}

// 날씨 정보 표시를 위한 서브 뷰 (예시)
struct WeatherInfoView: View {
    let weather: WeatherData

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(weather.name)
                    .font(.title)
                Spacer()
                // 날씨 아이콘 (OpenWeatherMap 아이콘 코드 사용)
                // 예: AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(weather.weather.first?.icon ?? "01d")@2x.png"))
                // Asset Catalog에 매핑된 아이콘 사용도 가능
                WeatherIconView(iconCode: weather.weather.first?.icon ?? "01d")
                    .font(.largeTitle)

            }
            Text("\(Int(round(weather.main.temp)))°C")
                .font(.system(size: 60, weight: .bold))
            Text(weather.weather.first?.description ?? "날씨 정보 없음")
                .font(.headline)
            Text("최고: \(Int(round(weather.main.tempMax)))°C / 최저: \(Int(round(weather.main.tempMin)))°C")
                .font(.subheadline)
        }
        .padding(.horizontal)
    }
}

// 옷차림 카드 서브 뷰 (예시)
struct OutfitCardView: View {
    let outfit: OutfitItem
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            // Asset Catalog의 이미지 이름으로 이미지 로드
            Image(outfit.imageName) // Asset Catalog에 해당 이름의 이미지가 있어야 함
                .resizable()
                .aspectRatio(contentMode: .fit) // 또는 .fill
                .frame(width: 150, height: 200) // 프레임 크기 조절
                .background(Color.gray.opacity(0.1)) // 이미지 없을 때 대비
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text(outfit.title)
                .font(.headline)
                .lineLimit(1)
            Text(outfit.description)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 150) // 카드 전체 너비
        .onTapGesture {
            onTap()
        }
    }
}

// Chip 스타일 버튼 컴포넌트
struct ChipButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
