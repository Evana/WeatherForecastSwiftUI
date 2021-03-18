//
//  Fetchable.swift
//  OpenWeather
//
//  Created by Evana Islam on 15/3/21.
//

import Foundation
protocol Fetchable {
    
    associatedtype FetchedType: Decodable
    /// End point last path component. Defaults to lowercase of FetchedType.
    static var urlEndPath: String? { get }
}

protocol FetchValue {
    var apiString: String { get }
}

extension Int: FetchValue {}
extension String: FetchValue {}

extension FetchValue {
    var apiString: String { String(describing: self) }
}

extension Fetchable {
    
    static var defaultURLEndPath: String {
        String(describing: self).lowercased()
    }
    
    /// Last path component of request URL. Defaults to self as a String, lowercased.
    static var urlEndPath: String? {
        defaultURLEndPath
    }
}
    
import Combine

extension Fetchable where FetchedType: Decodable {
    
    private static func dataPublisher(
        request: URLRequest
    ) -> AnyPublisher<Data, Error>
    {
        debugPrint("request = \(request), \(request.httpBody.map { String(data: $0, encoding: .utf8)?.prefix(200) ?? "" } ?? "")")
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse
                    else { throw Fetch.Error.statusCodeMissing }
                guard response.statusCode == 200 else {
                    if let error = try? JSONDecoder().decode(Fetch.Failure.Error.self, from: output.data) {
                        throw Fetch.Error.failure(error)
                    } else {
                        throw Fetch.Error.parsing(description: "Unable to parse error")
                    }
                }
            
                return output.data
        }
        .eraseToAnyPublisher()
    }
    
    private static func decodedPublisher(request: URLRequest,
                                         decoder: JSONDecoder = .decoder
    ) -> AnyPublisher<FetchedType, Error>
    {
        dataPublisher(request: request)
            .decode(type: FetchedType.self, decoder: decoder)
            .mapError {
                debugPrint("decoded(): error: \($0) for request: \(request)")
                return $0
            }
            .eraseToAnyPublisher()
    }
    
    static func request(keyValues: [String: FetchValue?]? = nil) throws -> URLRequest {
        
        let defaultKeyValues: [String: FetchValue] = ["mode": "json",
                                                   "units": "metric",
                                                   "appid": Environment().apiKey]
        let environment = Environment()
        let nonNilKeyValues = keyValues?.compactMapValues { $0 } ?? [:]
        let mergedKeyValues = defaultKeyValues
            .merging(nonNilKeyValues) { $1 }
        let queryItemsDictionary = mergedKeyValues
            .reduce(into: [:]) { result, tuple in
                result[tuple.key.apiString] = tuple.value.apiString
        }
        let urlPathComponents = [urlEndPath].compactMap { $0 }
        guard let url = environment.baseURL?.appendingPathComponents(urlPathComponents) else {
            throw Fetch.Error.url
        }
        guard let finalURL = try? url.addingQuery(dictionary: queryItemsDictionary) else {
            throw Fetch.Error.url
        }
        return URLRequest(url: finalURL)
    }
    
    static func publisher(
        keyValues: [String: FetchValue?]? = nil,
        decoder: JSONDecoder = .decoder
    ) -> AnyPublisher<FetchedType, Error>
    {
        do {
            return try decodedPublisher(request: request(keyValues: keyValues), decoder: decoder)
        } catch {
            return Fail<FetchedType, Error>(error: error)
                .eraseToAnyPublisher()
        }
    }
    
}

extension JSONDecoder {
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
