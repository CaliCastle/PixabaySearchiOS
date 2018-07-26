import Foundation

public struct Image {
    
    // MARK: - Properties
    
    /// Preview image url.
    public var imageUrl: String?
    
    /// Full size image url.
    public var fullSizeImageUrl: String?
    
    /// Tags in string.
    public var tags = ""
    
    /// Computed url property.
    public var url: URL? {
        return URL(string: imageUrl ?? "")
    }
    
    /// Computed full size url property.
    public var fullUrl: URL? {
        return URL(string: fullSizeImageUrl ?? "")
    }
    
    /// Quickly whip up an Image using Dictionary.
    ///
    /// - Parameter attributes: JSON parsed dictionary
    /// - Returns: Image instance
    static public func make(attributes: [String: Any]) -> Image? {
        guard let imageUrl = attributes["webformatURL"] as? String,
            let fullSizeImageUrl = attributes["largeImageURL"] as? String,
            let tags = attributes["tags"] as? String else { return nil }
        
        let instance = Image(imageUrl: imageUrl, fullSizeImageUrl: fullSizeImageUrl, tags: tags)
        
        return instance
    }
    
    /// Initializer.
    public init(imageUrl: String, fullSizeImageUrl: String, tags: String) {
        self.imageUrl = imageUrl
        self.fullSizeImageUrl = fullSizeImageUrl
        self.tags = tags
    }
    
}
