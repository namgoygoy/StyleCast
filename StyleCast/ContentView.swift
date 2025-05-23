//
//  ContentView.swift
//  StyleCast
//
//  Created by lee on 5/23/25.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var weatherVM = WeatherViewModel()

    var body: some View {
        VStack {
            if locationService.isLoading {
                ProgressView("Fetching location...")
            } else if let location = locationService.currentLocation {
                Text("Current Location:")
                    .font(.headline)
                Text("Latitude: \(location.coordinate.latitude)")
                Text("Longitude: \(location.coordinate.longitude)")

                if weatherVM.isLoadingWeather {
                    ProgressView("Fetching weather data...")
                } else if let currentWeatherData = weatherVM.currentWeather {
                    Text("Weather in \(currentWeatherData.name):")
                        .font(.headline)
                        .padding(.top)
                    Text("Temperature: \(currentWeatherData.main.temp, specifier: "%.1f")°C")
                    Text("Feels like: \(currentWeatherData.main.feelsLike, specifier: "%.1f")°C")
                    Text("Condition: \(currentWeatherData.weather.first?.description ?? "N/A")")
                    if let icon = currentWeatherData.weather.first?.icon {
                        AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png"))
                    }
                } else if let errorMessage = weatherVM.errorMessage {
                    Text("Error fetching weather: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding(.top)
                } else {
                    Text("Weather data not available yet.")
                        .padding(.top)
                }
            } else {
                Text("Location not available.")
                    .padding(.bottom)
                Button("Request Location Permission") {
                    locationService.requestLocationPermission()
                }
            }
        }
        .onAppear {
            locationService.requestLocationPermission()
            locationService.requestCurrentLocation()
        }
        .onChange(of: locationService.currentLocation) { newLocation in
            if let location = newLocation {
                Task {
                    await weatherVM.fetchCurrentWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                }
            }
        }
        .onChange(of: locationService.authorizationStatus) { newStatus in
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                locationService.requestCurrentLocation()
            } else if newStatus == .denied || newStatus == .restricted {
                weatherVM.resetWeatherData()
            }
        }
    }
}

class WeatherViewModel: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var weatherForecast: WeatherForecast?
    @Published var isLoadingWeather: Bool = false
    @Published var errorMessage: String?

    private let weatherService = WeatherService()

    @MainActor
    func fetchCurrentWeather(latitude: Double, longitude: Double) async {
        isLoadingWeather = true
        errorMessage = nil
        currentWeather = nil
        do {
            let weatherData = try await weatherService.getCurrentWeatherByLatLon(lat: latitude, lon: longitude)
            self.currentWeather = weatherData
            print("Successfully fetched current weather for lat: \(latitude), lon: \(longitude)")
        } catch {
            self.errorMessage = "Could not fetch current weather: \(error.localizedDescription)"
            if let networkError = error as? NetworkError {
                print("NetworkError: \(networkError)")
            } else {
                print("Other error: \(error)")
            }
        }
        isLoadingWeather = false
    }

    @MainActor
    func fetchFiveDayForecast(latitude: Double, longitude: Double) async {
        isLoadingWeather = true
        errorMessage = nil
        weatherForecast = nil
        do {
            let forecastData = try await weatherService.getFiveDayForecastByLatLon(lat: latitude, lon: longitude)
            self.weatherForecast = forecastData
            print("Successfully fetched 5-day forecast for lat: \(latitude), lon: \(longitude)")
        } catch {
            self.errorMessage = "Could not fetch 5-day forecast: \(error.localizedDescription)"
             if let networkError = error as? NetworkError {
                print("NetworkError: \(networkError)")
            } else {
                print("Other error: \(error)")
            }
        }
        isLoadingWeather = false
    }
    
    @MainActor
    func resetWeatherData() {
        currentWeather = nil
        weatherForecast = nil
        errorMessage = "Location permission denied or restricted. Weather data cannot be fetched."
        isLoadingWeather = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
