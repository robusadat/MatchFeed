import UIKit

final class ProfileCardCell: UICollectionViewCell {

    static let reuseID = "ProfileCardCell"
    var onSwipe: ((SwipeDirection) -> Void)?

    // MARK: - Views

    private let photoView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.preferredFont(forTextStyle: .title2)   // Dynamic Type
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.preferredFont(forTextStyle: .subheadline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Track the running async fetch so we can cancel on reuse
    private var imageTask: Task<Void, Never>?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask  = nil
        photoView.image = nil
        nameLabel.text  = nil
        locationLabel.text = nil
    }

    // MARK: - Configure

    func configure(with profile: UserProfile) {
        nameLabel.text     = profile.displayName
        locationLabel.text = profile.location

        // Accessibility
        accessibilityLabel = "\(profile.displayName), \(profile.location)"

        guard let url = profile.photoURL else { return }
        imageTask = Task { [weak self] in
            guard let self else { return }
            let image = await ImageCache.shared.loadOrFetch(url: url)
            guard !Task.isCancelled else { return }
            await MainActor.run { self.photoView.image = image }
        }
    }

    // MARK: - Layout

    private func setupViews() {
        contentView.addSubview(photoView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(locationLabel)

        // Bottom gradient for text legibility (no offscreen render — use CAGradientLayer directly)
        let gradient = CAGradientLayer()
        gradient.colors   = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.65).cgColor]
        gradient.locations = [0.5, 1.0]
        gradient.frame     = bounds
        photoView.layer.addSublayer(gradient)

        NSLayoutConstraint.activate([
            photoView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            photoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            locationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            nameLabel.bottomAnchor.constraint(equalTo: locationLabel.topAnchor, constant: -4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    // MARK: - Functions
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        switch gesture.state {
        case .changed:
            transform = CGAffineTransform(translationX: translation.x, y: translation.y / 4)
                .rotated(by: translation.x / 300)
                
        case .ended:
            if translation.x > 100 {
                onSwipe?(.like)
                UIView.animate(withDuration: 0.3) { self.transform = CGAffineTransform(translationX: 500, y: 0) }
            } else if translation.x < -100 {
                onSwipe?(.pass)
                UIView.animate(withDuration: 0.3) { self.transform = CGAffineTransform(translationX: -500, y: 0) }
            } else {
                UIView.animate(withDuration: 0.3) { self.transform = .identity }
            }
            
        default:
            break
        }
    }
}
