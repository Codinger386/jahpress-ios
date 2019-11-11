//
//  NetworkService.swift
//  RedOne
//
//  Created by Benjamin Ludwig on 01.11.18.
//  Copyright © 2018 nerdoc & codinger GmbH. All rights reserved.
//

import Foundation
import PromiseKit

enum NetworkServiceError: Error {
    case invalidURL(urlString: String)
    case failedToParseJSONData(data: Any?, error: Error)
    case unknown
}

public class NetworkService {

    public var baseUrl: URL?
    private var logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    public func post(to path: String, data: [String: Any]) -> Promise<Data> {

        guard let url = baseUrl?.appendingPathComponent(path) ?? URL(string: path) else {
            return Promise.init(error: NetworkServiceError.invalidURL(urlString: path))
        }

        var request = URLRequest(url: url)

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            request.httpMethod = "POST"
            request.httpBody = jsonData

            return self.send(request: request)
        } catch {

            return Promise(error: NetworkServiceError.failedToParseJSONData(data: data, error: error))
        }
    }

    public func patch(to path: String, data: [String: Any]) -> Promise<Data> {

        guard let url = baseUrl?.appendingPathComponent(path) ?? URL(string: path) else {
            return Promise.init(error: NetworkServiceError.invalidURL(urlString: path))
        }

        var request = URLRequest(url: url)

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            request.httpMethod = "POST"
            request.httpBody = jsonData

            return self.send(request: request)
        } catch {

            return Promise(error: NetworkServiceError.failedToParseJSONData(data: data, error: error))
        }
    }

    public func get(from path: String, data: [String: Any]? = nil) -> Promise<Data> {

        guard let url = baseUrl?.appendingPathComponent(path) ?? URL(string: path) else {
            return Promise.init(error: NetworkServiceError.invalidURL(urlString: path))
        }

        var urlComponents = URLComponents(string: url.absoluteString)!

        var queryParams: [URLQueryItem] = []
        if let data = data {
            for (key, value) in data {
                queryParams.append(URLQueryItem(name: key, value: String(describing: value)))
            }
        }

        urlComponents.queryItems = queryParams

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"

        return self.send(request: request)
    }

    private func send(request: URLRequest) -> Promise<Data> {

        let pending = Promise<Data>.pending()

        logger.info("DefaultNetworkService sending request: \(request)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            guard let data = data, error == nil else {
                self.logger.error("error: \(error ?? NetworkServiceError.unknown), response: \(String(describing: response))")
                pending.resolver.reject(error ?? NetworkServiceError.unknown)
                return
            }

            pending.resolver.fulfill(data)

//            do {
//                let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
//                pending.resolver.fulfill(responseJSON)
//            } catch {
//                pending.resolver.reject(NetworkServiceError.failedToParseJSONData(data: data, error: error))
//            }
        }
        task.resume()

        return pending.promise
    }
}
