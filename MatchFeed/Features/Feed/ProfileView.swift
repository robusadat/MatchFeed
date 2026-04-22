import SwiftUI

struct ProfileView: View {
    let profile: UserProfile
    var onLike: (() -> Void)?
    var onPass: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                photoSection
                infoSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Photo (50% of screen)
    private var photoSection: some View {
        GeometryReader { geo in
            AsyncImage(url: profile.photoURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.secondary
                }
            }
            .frame(width: geo.size.width, height: UIScreen.main.bounds.height * 0.5)
            .clipped()
        }
        .frame(height: UIScreen.main.bounds.height * 0.5 - 44)
    }

    // MARK: - Info
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Name + age
            HStack(alignment: .firstTextBaseline) {
                Text(profile.firstName)
                    .font(.largeTitle).bold()
                Text("\(profile.age)")
                    .font(.title).foregroundStyle(.secondary)
            }

            // Details
            VStack(alignment: .leading, spacing: 12) {
                infoRow(icon: "mappin.circle.fill",  color: .red,    text: profile.location)
                infoRow(icon: "envelope.circle.fill", color: .blue,   text: profile.email)
                infoRow(icon: "person.circle.fill",  color: .purple, text: profile.gender.capitalized)
            }

            Divider()

            // Like / Pass buttons
            HStack(spacing: 40) {
                Spacer()
                actionButton(icon: "xmark", color: .red) { onPass?() }
                actionButton(icon: "heart.fill", color: .pink) { onLike?() }
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color(.systemBackground))
    }

    private func infoRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 20))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 68, height: 68)
                .background(Color(.systemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}
