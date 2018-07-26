import UIKit
import AXPhotoViewer

/// Search text field throttle interval in milliseconds.
fileprivate let throttleInterval = 450

/// The y position for triggering loading next page.
fileprivate let loadNextPageTriggerY: CGFloat = 180

final class SearchCollectionViewController: UICollectionViewController {

    // MARK: - Properties
    
    /// Images data source.
    fileprivate var images = [Image]()
    
    /// Determine if waiting for the api.
    fileprivate var loading = false {
        didSet {
            // Listen for loading.
            if loading {
                // Create loading overlay.
                let loadingOverlay = UIView()
                loadingOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
                
                // Create the Activity Indicator.
                let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
                
                // Add to subviews.
                loadingOverlay.addSubview(activityIndicator)
                view.addSubview(loadingOverlay)
                
                // Set frame.
                loadingOverlay.frame = view.bounds
                activityIndicator.frame = view.bounds
                
                // Start the loading animation.
                activityIndicator.startAnimating()
                
                // Retain it.
                self.loadingOverlay = loadingOverlay
            } else {
                // Remove activity indicator
                loadingOverlay?.removeFromSuperview()
            }
        }
    }
    
    /// Loading overlay view.
    fileprivate weak var loadingOverlay: UIView?
    
    /// Stored last query string.
    fileprivate var lastQuery: String? {
        didSet {
            guard let query = lastQuery else { return }
            
            title = "Images for '\(query)'"
        }
    }
    
    /// Track current page.
    fileprivate var currentPage: Int = 1

    /// Track if there is a next page.
    fileprivate var hasNextPage: Bool = true
    
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
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set navigation title.
        title = "Pixabay Search"

        // Assign search controller.
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    /// Listen for scrolling.
    /// - Parameter scrollView: The scroll view
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !loading, hasNextPage, images.count > 0 else { return }
        
        // Calculate bottom origin in y axis.
        let currentBottom = scrollView.contentOffset.y + scrollView.bounds.size.height - searchController.searchBar.bounds.size.height
        
        // Load when passed trigger point.
        if scrollView.contentSize.height - currentBottom <= loadNextPageTriggerY,
            let collectionView = collectionView {
            // Stop scrolling
            collectionView.setContentOffset(collectionView.contentOffset, animated: false)
            
            loadNextPage()
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
            AXPhoto(attributedDescription: NSAttributedString(string: $0.title), attributedCredit: NSAttributedString(string: $0.description), url: $0.fullUrl)
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
            // Get current image view in collection cell.
            let indexPath = IndexPath(item: index, section: 0)
            
            if let cell = self?.collectionView?.cellForItem(at: indexPath) as? ImageCollectionViewCell {
                return cell.imageView
            }
            
            // Return selected image view if not found.
            return self?.selectedImageView
        }
        
        // Create photos view controller.
        let dataSource = AXPhotosDataSource(photos: photos, initialPhotoIndex: indexPath.item)
        let photosViewController = AXPhotosViewController(dataSource: dataSource, pagingConfig: nil, transitionInfo: transitionInfo)
        
        // Present it.
        present(photosViewController, animated: true)
    }
}

// MARK: - Search Methods

extension SearchCollectionViewController {
    
    /// Check if search bar text is empty.
    ///
    /// - Returns: `true` means empty
    fileprivate func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    /// Perform search action.
    ///
    /// - Parameter text: The text to be searched
    fileprivate func performSearch(_ text: String) {
        guard !searchBarIsEmpty() && lastQuery != text else { return }
        
        // Store last query.
        lastQuery = text
        
        // Reset page.
        currentPage = 1
        hasNextPage = true
        
        // Fetch images.
        fetchImages(by: text, at: currentPage) { [unowned self] in
            if let newImages = $0, newImages.count != 0 {
                // Update datasource and reload.
                self.images = newImages
                self.reloadData()
                
                // No more next page.
                if newImages.count != Api.default.perPage {
                    self.hasNextPage = false
                }
            }
        }
    }
    
    /// Load and append next page on last query.
    fileprivate func loadNextPage() {
        guard let query = lastQuery, hasNextPage else { return }
        
        // Increment current page.
        currentPage += 1
        
        // Fetch images.
        fetchImages(by: query, at: currentPage) { [unowned self] in
            if let newImages = $0, newImages.count != 0 {
                // Update datasource and reload.
                self.images.append(contentsOf: newImages)
                self.reloadData(shouldScroll: false)
                
                // No more next page.
                if newImages.count != Api.default.perPage {
                    self.hasNextPage = false
                }
            } else {
                // No more next page.
                self.hasNextPage = false
            }
        }
    }
    
    /// Make API search request.
    ///
    /// - Parameters:
    ///   - query: The query string
    ///   - page: Which page number
    ///   - completion: Closure to be executed
    fileprivate func fetchImages(by query: String, at page: Int, completion: @escaping ([Image]?) -> Void) {
        // Toggle loading state.
        loading = true
        
        // Call API.
        Api.default.search(query, page: currentPage) { [unowned self] in
            // Toggle loading state.
            self.loading = false
            
            completion($0)
        }
    }
    
    /// Reload collection data from data source.
    fileprivate func reloadData(shouldScroll: Bool = true) {
        DispatchQueue.main.async {
            // Batch update collection view.
            self.collectionView?.performBatchUpdates({
                self.collectionView?.reloadSections([0])
            })
            
            // Scroll to top
            if shouldScroll, (self.collectionView?.numberOfItems(inSection: 0))! > 0 {
                self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
            }
        }
    }
    
    /// Check if earching.
    ///
    /// - Returns: `true` means searching
    fileprivate func isSearching() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
}

// MARK: - Search Delegate

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
