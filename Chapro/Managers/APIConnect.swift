import Foundation

enum APIError: Error {
    case invalidParameter
    case serverError
    case timeout
    case unknown
    case custom(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidParameter:
            return "パラメータが不正です。"
        case .serverError:
            return "サーバーエラーが発生しました。"
        case .timeout:
            return "タイムアウトが発生しました。"
        case .unknown:
            return "不明なエラーが発生しました。"
        case .custom(let msg):
            return msg
        }
    }
}

class APIClient {
    static let baseURL = URL(string: "https://manage.chapro.jp/desktopApi/")!
    
    static func request(
        path: String,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Data? = nil,
        timeout: TimeInterval = 10,
        completion: @escaping (Result<Data, APIError>) -> Void
    ) {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        if method != "GET" {
            request.httpBody = body
        }
        request.timeoutInterval = timeout

        var finalHeaders: [String: String] = [
            "Content-Type": "application/json; charset=utf-8"
        ]
        
        if let code = DatabaseManager.shared.getSetting(key: "chapro") {
            finalHeaders["X-Desktop-Auth-Key"] = code
        }

        if let headers = headers {
            finalHeaders.merge(headers) { _, new in new }
        }
        
        request.allHTTPHeaderFields = finalHeaders

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error as? URLError, error.code == .timedOut {
                completion(.failure(.timeout))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Failed to cast response to HTTPURLResponse: \(String(describing: response))")

                completion(.failure(.unknown))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                completion(.success(data ?? Data()))
            case 400:
                completion(.failure(.invalidParameter))
            default:
                completion(.failure(.serverError))
            }
        }
        task.resume()
    }

}
