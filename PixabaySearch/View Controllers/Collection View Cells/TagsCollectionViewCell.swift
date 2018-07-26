import UIKit

class TagsCollectionViewCell: UICollectionViewCell {
 
    /// Reuse identifier.
    static let reuseIdentifier = "TagCell"
    
    // MARK: - Interface Outlets
    
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var tagLabel: UILabel!
    
    /// Tag dependency
    var tagString: String? {
        didSet {
            guard let tag = tagString else { return }
            
            tagLabel.text = tag
        }
    }
    
    /// Setup views.
    override func awakeFromNib() {
        tagView.layer.cornerRadius = tagView.bounds.height / 2
    }
    
}
