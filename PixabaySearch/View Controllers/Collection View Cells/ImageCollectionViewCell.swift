import UIKit
import AlamofireImage

class ImageCollectionViewCell: UICollectionViewCell {
    
    /// Reuse identifier.
    static let reuseIdentifier = "ImageCell"
    
    // MARK: - Interface Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    
    /// Image dependency
    var image: Image? {
        didSet {
            guard let image = image else { return }
            
            // Reset upon each assign.
            reset()
            
            // Load preview image url.
            if let imageUrl = image.url {
                imageView.af_setImage(withURL: imageUrl)
            }
            
            // Split tags into array.
            tags = image.tags.split(separator: ",").map {
                $0.trimmingCharacters(in: CharacterSet.whitespaces)
            }
        }
    }
    
    /// Tags in array format.
    fileprivate var tags: [String]? {
        didSet {
            guard let _ = tags else { return }
            
            DispatchQueue.main.async {
                self.tagsCollectionView.reloadData()
            }
        }
    }
    
    /// Setup views.
    override func awakeFromNib() {
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
    }
    
    /// Reset data.
    fileprivate func reset() {
        imageView.image = nil
        tags = nil
    }
    
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension ImageCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: UICollectionViewDataSource
    
    /// How many sections in collection view.
    ///
    /// - Parameter collectionView: Collection view
    /// - Returns: Number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /// How many items in given section.
    ///
    /// - Parameters:
    ///   - collectionView: Collection view
    ///   - section: Section index
    /// - Returns: Number of items
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags?.count ?? 0
    }
    
    /// Configure each cell.
    ///
    /// - Parameters:
    ///   - collectionView: Collection view
    ///   - indexPath: Index path
    /// - Returns: Configured cell instance
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagsCollectionViewCell.reuseIdentifier, for: indexPath) as? TagsCollectionViewCell else { fatalError("Unable to dequeue \(TagsCollectionViewCell.reuseIdentifier)") }
        
        // Configure cell.
        cell.tagString = tags?[indexPath.item]
        
        return cell
    }
    
    /// Modify cell size.
    ///
    /// - Parameters:
    ///   - collectionView: Collection view
    ///   - collectionViewLayout: Flow layout
    ///   - indexPath: Index path
    /// - Returns: Altered cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let tag = tags?[indexPath.item] else { return .zero }
        
        let height: CGFloat = 26
        let fontSize: CGFloat = 9
        
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = tag.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: UIFont(name: "AvenirNext-DemiBold", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize)], context: nil)
        
        return CGSize(width: ceil(boundingBox.width) + 16, height: height)
    }
}
