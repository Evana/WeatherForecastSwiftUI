//
//  WeeklyWeatherViewModelTests.swift
//  WeatherForecastTests
//
//  Created by Evana Islam on 17/3/21.
//

import XCTest
import Combine

@testable import WeatherForecast
class WeeklyWeatherViewModelTests: XCTestCase {

    private var subscribers: Set<AnyCancellable>!
    var viewModel: WeeklyWeatherViewModel?

    override func setUp() {
        super.setUp()
        viewModel = WeeklyWeatherViewModel(weather: Mock.currentWeather)
        subscribers = []
        viewModel?.onAppear()
    }
    
    func testLoadWeeklyData() {
        var error: Error?
        var weeklyWeather: WeeklyWeather?
        let expectation = self.expectation(description: "WeekluWeather")
        Fetch.WeeklyWeather.publisher(q: viewModel?.currentWeather.name ?? "")
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion{
                case .finished: break
                case.failure(let failureError):
                    error = failureError
                }
                expectation.fulfill()
            } receiveValue: { weather in
                weeklyWeather = weather
            }
            .store(in: &subscribers)
        waitForExpectations(timeout: 2)
        XCTAssertNil(error)
        XCTAssertEqual(weeklyWeather?.city.name, viewModel?.weeklyWeather?.city.name)
        XCTAssertEqual(weeklyWeather?.city.coordinate.latitute, viewModel?.weeklyWeather?.city.coordinate.latitute)
        XCTAssertEqual(weeklyWeather?.city.name, "Minto")
    }

}
