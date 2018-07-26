import Foundation
import Alamofire

final class Api {
    
    /// Singleton instance.
    static let `default` = Api()
    
    /// Base url.
    private let baseUrl = Configuration.apiBaseUrl
    
    /// Number of images per page.
    public var perPage = 36
    
    /// Response completion handler for api requests.
    typealias ResponseHandler = ([Image]?) -> Void
    
    /// Send API search request.
    ///
    /// - Parameters:
    ///   - query: text to be searched
    ///   - handler: completion block
    public func search(_ query: String, page: Int, handler: (ResponseHandler)? = nil) {
        Alamofire.request(Configuration.apiBaseUrl, method: HTTPMethod.get, parameters: ["key": Configuration.apiKey, "q": query, "image_type": "photo", "per_page": perPage, "page": page])
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                // Parse JSON to Dictionary
                if let json = response.result.value as? [String: Any],
                    let imagesJson = json["hits"] as? [[String: Any]] {
                    // Make a fresh image array
                    var images = [Image]()
                    
                    // Parse Dictionary into Image instances
                    imagesJson.forEach({
                        if let image = Image.make(attributes: $0) {
                            images.append(image)
                        }
                    })
                    
                    // Complete
                    handler?(images)
                } else {
                    // Failed
                    handler?(nil)
                }
        }
    }
    
    /// Private initializer.
    private init() {}
    
}
