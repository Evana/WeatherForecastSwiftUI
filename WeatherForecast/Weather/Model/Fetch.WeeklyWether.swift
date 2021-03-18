//
//  Fetch.HourlyWether.swift
//  OpenWeather
//
//  Created by Evana Islam on 16/3/21.
//

import Foundation
import Combine

extension Fetch {
    enum WeeklyWeather {}
}

extension Fetch.WeeklyWeather: Fetchable {
    typealias FetchedType = WeeklyWeather
    static var urlEndPath: String? { "forecast" }
}

extension Fetch.WeeklyWeather {
    static func publisher(q: String) -> AnyPublisher<FetchedType, Error> {
        publisher(keyValues: ["q": q])
            .eraseToAnyPublisher()
    }
}
