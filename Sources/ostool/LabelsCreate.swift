import Foundation
import RxSwift
import RxBlocking

func createLabels(repository: String) {
    guard let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"] else {
        print("Environment variable GITHUB_TOKEN not set")
        return
    }
    print("Creating default labels in repository github.com/\(repository)")
    let result = deleteLabels(in: repository, token: token)
        .do(onCompleted: { print("Current labels deleted, creating labels") })
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
    let deleteLabel: (String) -> Observable<Any> = { (labelName) in
        return request(path: "repos/\(repository)/labels/\(labelName)", method: "DELETE", token: token)
    }
    let deleteLabels: ([String]) -> Observable<Void> = { (labels: [String]) in
        return Observable.combineLatest(labels.map(deleteLabel)).map({_ in return ()})
    }
    return getLabels(in: repository, token: token)
        .do(onNext: { _ in print("> Current labels fetched, deleting them") })
        .flatMap({ deleteLabels($0) })
}

fileprivate func createLabels(in repository: String, token: String) -> Observable<Void> {
    let createLabel = { (name: String, color: String) in
        return request(path: "/repos/\(repository)/labels", method: "POST", body: [ "name": "name", "color": "color"], token: token)
    }
    let observables = [
        createLabel("difficulty:easy", "d93f0b"),
        createLabel("difficulty:moderate", "d93f0b"),
        createLabel("difficulty:hard", "d93f0b"),
        createLabel("priority:low", "fbca04"),
        createLabel("priority:medium", "fbca04"),
        createLabel("priority:high", "fbca04"),
        createLabel("status:blocked", "0e8a16"),
        createLabel("status:ready-development", "0e8a16"),
        createLabel("status:wip", "0e8a16"),
        createLabel("status:waiting-input", "0e8a16"),
        createLabel("status:waiting-review", "0e8a16"),
        createLabel("type:bug", "1d76db"),
        createLabel("type:enhancement", "1d76db"),
        createLabel("type:feature", "1d76db"),
        createLabel("type:tech-debt", "1d76db"),
        createLabel("type:thread", "1d76db")
    ]
    return Observable.combineLatest(observables)
        .map({ _ in return ()})
}

fileprivate func getLabels(in repository: String, token: String) -> Observable<[String]> {
    return request(path: "/repos/\(repository)/labels", method: "GET", token: token)
        .map({ (json) -> [String] in
            let array = (json as? [[String: Any]]) ?? []
            return array.flatMap({ (label) -> String? in
                return label["name"] as? String
            })
        })
}

fileprivate func request(path: String, method: String, parameters: [String: String] = [:], body: [String: Any] = [:], token: String) -> Observable<Any> {
    var url = URL(string: "https://api.github.com/")!
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    components.path = path
    components.queryItems = parameters.map({URLQueryItem(name: $0.key, value: $0.value)})
    url = components.url!
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.allHTTPHeaderFields = [:]
    request.allHTTPHeaderFields?["Accept"] = "application/vnd.github.v3+json"
    request.allHTTPHeaderFields?["Authorization"] = "token \(token)"
    request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
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

