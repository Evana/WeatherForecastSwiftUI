//
//  Fetch.swift
//  OpenWeather
//
//  Created by Evana Islam on 16/3/21.
//

import Foundation

enum Fetch {}

extension Fetch {
    
    enum Error: Swift.Error {
        case parsing(description: String)
        case network(description: String)
        case url
    }
}

struct Environment {
    var baseURLString: String {
        "https://api.openweathermap.org/data/2.5/"
    }
    
    var apiKey: String {
        "c7e00bb14b77907fe81bbd2f32438cfd"
    }
    
    var baseURL: URL? {
        URL(string: baseURLString)
    }
}

struct Confirmation: Decodable {
    let title: String?
    let message: String?
}
