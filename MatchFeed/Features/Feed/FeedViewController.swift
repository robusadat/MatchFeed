import UIKit
import Observation

// MARK: - FeedViewController
// UIKit view controller using:
//   • UICollectionViewCompositionalLayout  — modern declarative layout
//   • NSDiffableDataSource                 — crash-free animated updates
//   • UICollectionViewDataSourcePrefetching — eager image prefetch
//   • @Observable ViewModel               — via manual withObservationTracking

private typealias FeedDataSource = UICollectionViewDiffableDataSource<String, String>
private typealias FeedSnapshot   = NSDiffableDataSourceSnapshot<String, String>

final class FeedViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: FeedViewModel
    private var collectionView: UICollectionView!
    private var dataSource: FeedDataSource!
    var coordinator: AppCoordinator?

    // MARK: - Init
    init(viewModel: FeedViewModel = FeedViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Discover"
        view.backgroundColor = .systemBackground
        setupCollectionView()
        setupDataSource()
        observeViewModel()
        Task { await viewModel.loadInitial() }
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: makeLayout()
        )
        collectionView.autoresizingMask  = [.flexibleWidth, .flexibleHeight]
        collectionView.prefetchDataSource = self
        collectionView.register(
            ProfileCardCell.self,
            forCellWithReuseIdentifier: ProfileCardCell.reuseID
        )
        collectionView.delegate = self
        view.addSubview(collectionView)
    }

    private func makeLayout() -> UICollectionViewLayout {
        // Card layout: full-width, fixed height
        let itemSize  = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item  = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(440)
        )
        let group   = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupDataSource() {
        dataSource = FeedDataSource(collectionView: collectionView) { [weak self] cv, indexPath, profileId in
            let cell = cv.dequeueReusableCell(
                withReuseIdentifier: ProfileCardCell.reuseID,
                for: indexPath
            ) as! ProfileCardCell
            if let profile = self?.viewModel.profiles.first(where: { $0.id == profileId }) {
                cell.configure(with: profile)
                cell.onSwipe = { [weak self] direction in
                    guard let profile = self?.viewModel.profiles.first(where: { $0.id == profileId }) else { return }
                    Task { await self?.viewModel.swipe(profile: profile, direction: direction) }
                }
            }
            Task { await self?.viewModel.loadMoreIfNeeded(currentIndex: indexPath.item) }
            return cell
        }
    }

    // MARK: - Observation
    // Uses withObservationTracking to re-render whenever @Observable properties change.

    private func observeViewModel() {
        func track() {
            withObservationTracking {
                // Access every property we want to observe
                let profiles = self.viewModel.profiles
                let loading  = self.viewModel.isLoading

                DispatchQueue.main.async {
                    self.applySnapshot(profiles: profiles)
                    // TODO: show/hide loading spinner based on `loading`
                    _ = loading
                }
            } onChange: {
                // Called on any change — re-register to keep observing
                DispatchQueue.main.async { track() }
            }
        }
        track()
    }

    private func applySnapshot(profiles: [UserProfile]) {
        var snapshot = FeedSnapshot()
        snapshot.appendSections(["main"])
        snapshot.appendItems(profiles.map(\.id), toSection: "main")
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Prefetching

extension FeedViewController: UICollectionViewDataSourcePrefetching {

    func collectionView( _ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap {
            viewModel.profiles[safe: $0.item]?.photoURL
        }
        // Fire-and-forget: warm both memory and disk cache
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = await ImageCache.shared.loadOrFetch(url: url)
                    }
                }
            }
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        // With a library like Nuke you'd cancel here.
        // Our custom actor cache simply lets in-flight tasks complete — they'll populate the cache.
    }
    
}

extension FeedViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let profile = viewModel.profiles[safe: indexPath.item] else { return }
        coordinator?.showChat(with: profile)
    }
}

// MARK: - Helpers

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
