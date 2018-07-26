import UIKit
import AXPhotoViewer

/// Search text field throttle interval in milliseconds.
fileprivate let throttleInterval = 450

final class SearchCollectionViewController: UICollectionViewController {

    // MARK: - Properties
    
    /// Images data source.
    fileprivate var images = [Image]()
    
    /// Determine if waiting for the api.
    fileprivate var loading = false {
        didSet {
            // Listen for loading.
            if loading {
                // Create the Activity Indicator
                let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
                // Add it to view.
                view.addSubview(activityIndicator)
                // Set frame.
                activityIndicator.frame = view.bounds
                // Start the loading animation.
                activityIndicator.startAnimating()
                // Retain it.
                self.activityIndicator = activityIndicator
            } else {
                // Remove activity indicator
                activityIndicator?.removeFromSuperview()
            }
        }
    }
    
    /// Activity loading indicator.
    fileprivate var activityIndicator: UIActivityIndicatorView?
    
    /// Stored last query string.
    fileprivate var lastQuery: String? {
        didSet {
            guard let query = lastQuery else { return }
            
            title = "Images for '\(query)'"
        }
    }
    
    /// Track current page.
    fileprivate var currentPage: Int = 1
    
    /// Search controller setup.
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.tintColor = .white
        searchController.searchBar.keyboardAppearance = .dark
        searchController.searchBar.placeholder = "Search images"
        searchController.searchBar.delegate = self
        
        return searchController
    }()
    
    /// Segue enum.
    ///
    /// - ShowImage: Show image detail
    private enum Segue: String {
        case ShowImage
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set navigation title.
        title = "Pixabay Search"

        // Assign search controller.
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    /// Check if search bar text is empty.
    ///
    /// - Returns: `true` means empty
    fileprivate func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    /// Perform API search.
    ///
    /// - Parameter text: The text to be searched
    fileprivate func performSearch(_ text: String) {
        guard !searchBarIsEmpty() && lastQuery != text else { return }
        
        // Toggle loading state.
        loading = true
        
        // Store last query.
        lastQuery = text
        
        // Call api
        Api.default.search(text, page: currentPage) { [unowned self] in
            // Toggle loading state.
            self.loading = false
            
            if let newImages = $0, newImages.count != 0 {
                // Update datasource.
                if self.currentPage == 1 {
                    self.images = newImages
                }
                
                // Increment current page.
                self.currentPage += 1
                
                DispatchQueue.main.async {
                    // Batch update collection view.
                    self.collectionView.performBatchUpdates({
                        self.collectionView.reloadSections([0])
                    })
                    // Scroll to top
                    if self.collectionView.numberOfItems(inSection: 0) > 0 {
                        self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
                    }
                }
            }
        }
    }
    
    /// Check if earching.
    ///
    /// - Returns: `true` means searching
    fileprivate func isSearching() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    // MARK: - Navigation
    
    /// Preparation before navigation.
    ///
    /// - Parameters:
    ///   - segue: segue
    ///   - sender: object sent over
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier,
            identifier == Segue.ShowImage.rawValue,
            let image = sender as? Image,
            let viewImageViewController = segue.destination as? ViewImageViewController {
            viewImageViewController.image = image
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    /// How many sections in collection view.
    ///
    /// - Parameter collectionView: Collection view
    /// - Returns: Number of sections
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /// How many items in given section.
    ///
    /// - Parameters:
    ///   - collectionView: Collection view
    ///   - section: Section index
    /// - Returns: Number of items
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    
    /// Configure each cell.
    ///
    /// - Parameters:
    ///   - collectionView: Collection view
    ///   - indexPath: Index path
    /// - Returns: Configured cell instance
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.reuseIdentifier, for: indexPath) as? ImageCollectionViewCell else { fatalError("Unable to dequeue \(ImageCollectionViewCell.reuseIdentifier)") }
        
        // Configure the cell
        let image = images[indexPath.item]
        
        cell.image = image
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    /// Computed photos property for image viewer.
    fileprivate var photos: [AXPhoto] {
        return images.compactMap {
            AXPhoto(url: $0.fullUrl)
        }
    }
    
    /// Stored selected image view.
    fileprivate weak var selectedImageView: UIImageView?
    
    /// When the collection view cell is tapped.
    ///
    /// - Parameters:
    ///   - collectionView: Collection view
    ///   - indexPath: Index path of cell
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Dismiss search controller.
        searchController.isActive = false
        // Reset selected image view.
        selectedImageView = nil
        
        // Retreive collection cell.
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell else { return }
        // Assign currently selected image view.
        selectedImageView = cell.imageView
        // Make transition info.
        let transitionInfo = AXTransitionInfo(interactiveDismissalEnabled: true, startingView: selectedImageView) { [weak self] (photo, index) -> UIImageView? in
            return self?.selectedImageView
        }
        // Create photos view controller.
        let dataSource = AXPhotosDataSource(photos: photos, initialPhotoIndex: indexPath.item)
        let photosViewController = AXPhotosViewController(dataSource: dataSource, pagingConfig: nil, transitionInfo: transitionInfo)
        
        // Present it.
        present(photosViewController, animated: true)
    }
}

extension SearchCollectionViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    /// Update search results for input.
    ///
    /// - Parameter searchController: Search Controller
    func updateSearchResults(for searchController: UISearchController) {
        // Throttle api requests.
        DispatchQueue.main.throttle(deadline: .now() + .milliseconds(throttleInterval)) {
            self.performSearch(searchController.searchBar.text!)
        }
    }
    
    /// When search button was tapped.
    ///
    /// - Parameter searchBar: Search bar
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch(searchBar.text!)
    }
    
}
