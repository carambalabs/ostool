import Foundation
import RxSwift
import RxBlocking

func createLabels(repository: String) {
    guard let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"] else {
        print("Environment variable GITHUB_TOKEN not set")
        return
    }
    let result = deleteLabels(in: repository, token: token)
        .concat(createLabels(in: repository, token: token))
        .toBlocking()
        .materialize()
    switch result {
    case .completed(_):
        print("Labels created")
    case .failed(_, let error):
        print("Error creating labels: \(error)")
    }
}

fileprivate func deleteLabels(in repository: String, token: String) -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
        return Disposables.create()
    }
}

fileprivate func createLabels(in repository: String, token: String) -> Observable<Void> {
    return Observable.create { (observer) -> Disposable in
        return Disposables.create()
    }
}

fileprivate func request(path: String, method: String, parameters: [String: String], token: String) -> Observable<Any> {
    var url = URL(string: "https://api.github.com/")!
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    components.path = path
    components.queryItems = parameters.map({URLQueryItem(name: $0.key, value: $0.value)})
    url = components.url!
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.allHTTPHeaderFields = [:]
    request.allHTTPHeaderFields?["Accept"] = "application/vnd.github.v3+json"
    request.allHTTPHeaderFields?["Authorization"] = "Authorization: token \(token)"
    return Observable.create { observer -> Disposable in
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                observer.onError(error)
                return
            }
            let urlResponse = response as! HTTPURLResponse
            switch urlResponse.statusCode {
            case 200..<300:
                if let data = data {
                    let json = try! JSONSerialization.jsonObject(with: data, options: [])
                    observer.onNext(json)
                    observer.onCompleted()
                } else {
                    observer.onCompleted()
                }
            default:
                observer.onError(NSError(domain: "github-api", code: urlResponse.statusCode, userInfo: nil))
            }
        }
        task.resume()
        return Disposables.create {
            task.cancel()
        }
    }
}

