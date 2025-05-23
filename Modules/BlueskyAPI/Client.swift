import Foundation
import ATAT

enum ClientError: Error {
	case malformedURL(URLComponents)
	case requestFailed
	case invalidArguments
}

public actor Client: Sendable {
	public typealias ResponseProvider = @Sendable (URLRequest) async throws -> (Data, URLResponse)
	
	private let provider: ResponseProvider
	public let host: String
	public let account: String
	private let decoder = ATJSONDecoder()
	
	public init(host: String, account: String, provider: @escaping ResponseProvider) {
		self.provider = provider
		self.host = host
		self.account = account
	}
	
	private var baseComponents: URLComponents {
		var components = URLComponents()
		components.scheme = "https"
		components.host = host
		
		return components
	}
}

public struct Credentials: Hashable, Codable, Sendable {
	public let identifier: String
	public let password: String
	
	public init(identifier: String, password: String) {
		self.identifier = identifier
		self.password = password
	}
}

public enum AccountStatus: String, Decodable, Hashable, Sendable {
	case takenDown = "takendown"
	case suspended
	case deactivated
}

public struct CreateSessionResponse: Decodable, Hashable, Sendable {
	public let accessJwt: String
	public let refreshJwt: String
	public let handle: String
	public let did: ATProtoDID
	public let email: String
	public let emailConfirmed: Bool
	public let emailAuthFactor: Bool
	public let active: Bool
	public let status: AccountStatus?
}

extension Client {
	public func createSession(with login: Credentials) async throws -> CreateSessionResponse {
		var components = baseComponents
		
		components.path = "/xrpc/com.atproto.server.createSession"
		
		guard let url = components.url else {
			throw ClientError.malformedURL(components)
		}

		var request = URLRequest(url: url)
		
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try JSONEncoder().encode(login)
		
		let (data, _) = try await provider(request)
		
		return try decoder.decode(CreateSessionResponse.self, from: data)
	}
	
	public func timeline() async throws -> Bsky.Feed.GetFeedResponse {
		var components = baseComponents
		
		components.path = "/xrpc/app.bsky.feed.getTimeline"
		
		guard let url = components.url else {
			throw ClientError.malformedURL(components)
		}

		var request = URLRequest(url: url)
		
		request.httpMethod = "GET"
		
		let (data, response) = try await provider(request)
		
		guard
			let httpResponse = response as? HTTPURLResponse,
			httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
		else {
			print("response:", response)
			print(String(decoding: data, as: UTF8.self))
			throw ClientError.requestFailed
		}
		
		return try decoder.decode(Bsky.Feed.GetFeedResponse.self, from: data)
	}
	
	public func likePost(cid: ATProtoCID, uri: ATProtoURI) async throws {
		var components = baseComponents
		
		components.path = "/xrpc/com.atproto.repo.createRecord"
		
		guard let url = components.url else {
			throw ClientError.malformedURL(components)
		}

		let like = Bsky.Feed.Like(
			createdAt: .now,
			subject: Bsky.Repo.StrongRef(
				cid: cid,
				uri: uri
			)
		)
		
		let createRecord = Bsky.Repo.CreateRecord.Request(
			repo: account,
			collection: .feedLike,
			record: .feedLike(like)
		)
		
		var request = URLRequest(url: url)
		
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		request.httpBody = try ATJSONEncoder().encode(createRecord)
		
		let (data, _) = try await provider(request)
		
		print(String(decoding: data, as: UTF8.self))
		
		_ = try decoder.decode(Bsky.Repo.CreateRecord.Response.self, from: data)
	}
}
