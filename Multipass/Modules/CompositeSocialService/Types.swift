import Foundation
import CoreGraphics

public enum DataSource: String, Hashable, Sendable, Codable, CaseIterable {
	case mastodon
	case bluesky
	
	/// The symbol asset name
	public var imageName: String {
		switch self {
		case .mastodon:
			"mastodon.clean.fill"
		case .bluesky:
			"bluesky"
		}
	}
}

extension DataSource: CustomStringConvertible {
	public var description: String {
		switch self {
		case .mastodon: "Mastodon"
		case .bluesky: "Bluesky"
		}
	}
}

public struct Author: Hashable, Sendable {
	public let name: String
	public let handle: String
	public let avatarURL: URL?
	
	public init(name: String, handle: String, avatarURL: URL? = nil) {
		self.name = name
		self.handle = handle
		self.avatarURL = avatarURL
	}
	
	public static let placeholder = Author(name: "placeholder", handle: "placeholder")
}

public enum Attachment: Hashable, Sendable {
	public struct ImageSpecifier: Hashable, Sendable {
		public let url: URL
		public let size: CGSize?
		public let focus: CGPoint?
	}
	
	public struct Image: Hashable, Sendable {
		public let preview: ImageSpecifier?
		public let full: ImageSpecifier
		public let description: String?
		
		public init(preview: ImageSpecifier?, full: ImageSpecifier, description: String?) {
			self.preview = preview
			self.full = full
			self.description = description
		}
	}
	
	public struct Link: Hashable, Sendable {
		public let preview: ImageSpecifier?
		public let description: String?
		public let title: String?
		public let url: URL
		
		public init(preview: ImageSpecifier?, description: String?, title: String?, url: URL) {
			self.preview = preview
			self.description = description
			self.title = title
			self.url = url
		}
	}
	
	case images([Image])
	case link(Link)
}

public struct PostStatus: Hashable, Sendable {
	public let likeCount: Int
	public let liked: Bool
	public let repostCount: Int
	public let reposted: Bool
	
	public init(likeCount: Int, liked: Bool, repostCount: Int, reposted: Bool) {
		self.likeCount = likeCount
		self.liked = liked
		self.repostCount = repostCount
		self.reposted = reposted
	}
	
	public static let placeholder = PostStatus(likeCount: 5, liked: false, repostCount: 150, reposted: true)
}

public struct Post: Hashable, Sendable {
	public let content: String?
	public let source: DataSource
	public let date: Date
	public let author: Author
	public let repostingAuthor: Author?
	public let identifier: String
	public let url: URL?
	public let attachments: [Attachment]
	public let status: PostStatus
	
	public init(
		content: String?,
		source: DataSource,
		date: Date,
		author: Author,
		repostingAuthor: Author?,
		identifier: String,
		url: URL?,
		attachments: [Attachment],
		status: PostStatus
	) {
		self.content = content
		self.source = source
		self.date = date
		self.author = author
		self.repostingAuthor = repostingAuthor
		self.identifier = identifier
		self.url = url
		self.attachments = attachments
		self.status = status
	}
	
	public static let placeholder = Post(
		content: "hello",
		source: .mastodon,
		date: .now,
		author: Author.placeholder,
		repostingAuthor: nil,
		identifier: "abc123",
		url: URL(string: "https://example.com")!,
		attachments: [],
		status: .placeholder
	)
}

extension Post: Identifiable {
	public var id: String {
		"\(source)-\(identifier)"
	}
}

extension Post: Comparable {
	public static func < (lhs: Post, rhs: Post) -> Bool {
		lhs.date < rhs.date
	}
}
