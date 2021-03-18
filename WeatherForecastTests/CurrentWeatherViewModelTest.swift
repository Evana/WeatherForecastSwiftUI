//
//  CurrentWeatherViewModelTest.swift
//  WeatherForecastTests
//
//  Created by Evana Islam on 18/3/21.
//

import XCTest
import Combine

@testable import WeatherForecast
class CurrentWeatherViewModelTest: XCTestCase {

    private var subscribers: Set<AnyCancellable>!
    var viewModel: CurrentWeatherViewModel?

    override func setUp() {
        super.setUp()
        viewModel = CurrentWeatherViewModel()
        viewModel?.city = "Minto"
        subscribers = []
        viewModel?.onAppear()
    }
    
    override func tearDown() {
        viewModel = nil
        subscribers = []
        super.tearDown()
    }
    func testLoadWeeklyData() {
        var error: Error?
        var currentWeather: CurrentWeather?
        let expectation = self.expectation(description: "WeekluWeather")
        Fetch.CurrentWeather.publisher(q: viewModel?.city ?? "")
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion{
                case .finished: break
                case.failure(let failureError):
                    error = failureError
                }
                expectation.fulfill()
            } receiveValue: { [weak self] weather in
                currentWeather = weather
                self?.viewModel?.weathers.append(weather)
            }
            .store(in: &subscribers)
        waitForExpectations(timeout: 2)
        XCTAssertNil(error)
        XCTAssertEqual(currentWeather?.name, viewModel?.sortedWeathers.first?.name)
        XCTAssertEqual(currentWeather?.coordinate.latitute, viewModel?.sortedWeathers.first?.coordinate.latitute)
    }

}
