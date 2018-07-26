import Foundation

public struct Image {
    
    // MARK: - Properties
    
    /// Preview image url.
    public let imageUrl: String
    
    /// Full size image url.
    public let fullSizeImageUrl: String
    
    /// Tags in string.
    public let tags: String
    
    /// Image's title.
    public let title: String
    
    /// Image's description.
    public let description: String
    
    /// Computed url property.
    public var url: URL? {
        return URL(string: imageUrl)
    }
    
    /// Computed full size url property.
    public var fullUrl: URL? {
        return URL(string: fullSizeImageUrl)
    }
    
    /// Quickly whip up an Image using Dictionary.
    ///
    /// - Parameter attributes: JSON parsed dictionary
    /// - Returns: Image instance
    static public func make(attributes: [String: Any]) -> Image? {
        guard let imageUrl = attributes["webformatURL"] as? String,
            let fullSizeImageUrl = attributes["largeImageURL"] as? String,
            let tags = attributes["tags"] as? String,
            let user = attributes["user"] as? String,
            let comments = attributes["comments"] as? Int,
            let likes = attributes["likes"] as? Int,
            let downloads = attributes["downloads"] as? Int
            else { return nil }
        
        let instance = Image(imageUrl: imageUrl, fullSizeImageUrl: fullSizeImageUrl, tags: tags, title: "Uploaded by: @\(user)", description: "\(comments) Comments, \(likes) Likes, \(downloads) Downloads")
        
        return instance
    }
    
    /// Initializer.
    public init(imageUrl: String, fullSizeImageUrl: String, tags: String, title: String, description: String) {
        self.imageUrl = imageUrl
        self.fullSizeImageUrl = fullSizeImageUrl
        self.tags = tags
        self.title = title
        self.description = description
    }
    
}
