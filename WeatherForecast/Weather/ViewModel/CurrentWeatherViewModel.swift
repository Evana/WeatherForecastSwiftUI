//
//  CurrentWeatherViewModel.swift
//  OpenWeather
//
//  Created by Evana Islam on 16/3/21.
//

import Foundation
import Combine

class CurrentWeatherViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var weathers: [CurrentWeather] = []
    @Published var error: Fetch.Error?
    @Published var segment: Segment = .postCode
    private var subscribers = Set<AnyCancellable>()
    
    var sortedWeathers: [CurrentWeather] {
        Array(weathers.filter { $0.date.isInToday }
                .sorted { $0.date > $1.date }
                .prefix(5))
    }
    
    var errorText: String? {
        guard case .failure(let fetchError) = error else { return nil }
        return fetchError.message
    }
}

// MARK: Functions

extension CurrentWeatherViewModel {
    func onAppear() {
        if subscribers.isEmpty {
            $text
                .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
                .filter { !$0.isEmpty }
                .sink(receiveValue: { [weak self] text in
                    guard let self = self else {return}
                    self.fetchCurrentWeather(text: text)
                })
                .store(in: &subscribers)
        }
        $segment.sink { [weak self] _ in
            guard let self = self else {return}
            self.text = ""
            self.error = nil
        }
        .store(in: &subscribers)
        self.loadRecentWeathers()
    }
    
    func onDisappear() {
        subscribers = []
    }
    
    func fetchCurrentWeather(text: String) {
        var publisher: AnyPublisher<CurrentWeather, Error>?
        switch segment {
        case .postCode:
            publisher = Fetch.CurrentWeather.publisher(q: text)
        case .gps:
            let coordinates = text.components(separatedBy: ",")
            guard coordinates.count == 2 else {
                error = Fetch.Error.url
                return
            }
            for coordinate in coordinates {
                guard let _ = Double(coordinate.trimmingCharacters(in: .whitespaces)) else {
                    error = Fetch.Error.url
                    return
                }
            }
            publisher = Fetch.CurrentWeather.publisher(lat: coordinates[0].trimmingCharacters(in: .whitespaces), lon: coordinates[1].trimmingCharacters(in: .whitespaces))
        }
        publisher?
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard case let .failure(error) = result,
                      let fetchError = error as? Fetch.Error
                else {
                    return
                }
                self?.error = fetchError
            }) { [weak self] currentWeather in
                self?.weathers.append(currentWeather)
                self?.saveWeather(currentWeather)
                self?.error = nil
            }
            .store(in: &subscribers)
    }
}

// MARK: Private functions

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

extension CurrentWeatherViewModel {
    enum Segment: CaseIterable, Identifiable {
        case postCode
        case gps
        
        var title: String {
            switch self {
            case .postCode: return "Name/Post Code"
            case .gps: return "Coordinates"
            }
        }
        
        var id: Self { self }
    }
}
