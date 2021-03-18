//
//  Fetch+CityWeather.swift
//  OpenWeather
//
//  Created by Evana Islam on 16/3/21.
//

import Foundation
import Combine

extension Fetch {
    enum CurrentWeather {}
}

extension Fetch.CurrentWeather: Fetchable {
    typealias FetchedType = CurrentWeather
    static var urlEndPath: String? { "weather" }
}

extension Fetch.CurrentWeather {
    static func publisher(q: String) -> AnyPublisher<FetchedType, Error> {
        publisher(keyValues: ["q": q])
            .eraseToAnyPublisher()
    }
}
