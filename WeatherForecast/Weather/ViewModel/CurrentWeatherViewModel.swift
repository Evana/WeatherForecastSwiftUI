//
//  CurrentWeatherViewModel.swift
//  OpenWeather
//
//  Created by Evana Islam on 16/3/21.
//

import Foundation
import Combine

class CurrentWeatherViewModel: ObservableObject {
    @Published var city: String = ""
    @Published var weathers: [CurrentWeather] = []
    @Published var error: Error?
    private var subscribers = Set<AnyCancellable>()
    
    var sortedWeathers: [CurrentWeather] {
        Array(weathers.filter { $0.date.isInToday }
                .sorted { $0.date > $1.date }
                .prefix(5))
    }
}
extension CurrentWeatherViewModel {
    func onAppear() {
        if subscribers.isEmpty {
            $city
                .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
                .filter { !$0.isEmpty }
                .sink(receiveValue: { [weak self] q in
                    guard let self = self else {return}
                    self.fetchCurrentWeather(q: q)
                })
                .store(in: &subscribers)
        }
        self.loadRecentWeathers()
    }
    
    func onDisappear() {
        subscribers = []
    }
    
    func fetchCurrentWeather(q: String) {
        Fetch.CurrentWeather.publisher(q: q)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard case let .failure(error) = result else { return }
                self?.error = error
            }) { [weak self] currentWeather in
                self?.weathers.append(currentWeather)
                self?.saveWeather(currentWeather)
            }
            .store(in: &subscribers)
    }
    
    func temmperature(currentWeather: CurrentWeather) -> String {
        "\(currentWeather.weatherDetail.temperature.toInt() ?? 0)" + "°"
    }
}

extension CurrentWeatherViewModel {
    private func saveWeather(_ weather: CurrentWeather) {
        var weathers = UserDefaults.standard.currentWeathers ?? []
        weathers.append(weather)
        UserDefaults.standard.currentWeathers = weathers
    }
    
    private func loadRecentWeathers() {
        weathers = UserDefaults.standard.currentWeathers ?? []
    }
}
