import Foundation

struct Chat: Codable, Identifiable {
    let id: String
    private(set) var participants: [User]
    private(set) var participantIds: [String]
    var lastMessage: String
    var lastMessageAt: Date
    var unreadCount: [String: Int]
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case participants
        case lastMessage
        case lastMessageAt
        case unreadCount
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode ID
        id = try container.decode(String.self, forKey: .id)
        
        // Handle participants - could be array of strings or User objects
        if let participantStrings = try? container.decode([String].self, forKey: .participants) {
            participantIds = participantStrings
            // Initialize with minimal User objects
            participants = participantStrings.map { id in
                User(id: id, username: "", bio: nil, fullName: nil, profileImage: nil, followers: [], following: [])
            }
        } else if let userObjects = try? container.decode([User].self, forKey: .participants) {
            participants = userObjects
            participantIds = userObjects.compactMap { $0.id }
        } else {
            throw DecodingError.dataCorruptedError(forKey: .participants, in: container, debugDescription: "Participants must be either string IDs or User objects")
        }
        
        // Decode lastMessage with empty string default
        lastMessage = (try? container.decode(String.self, forKey: .lastMessage)) ?? ""
        
        // Handle date decoding
        if let dateString = try? container.decode(String.self, forKey: .lastMessageAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            lastMessageAt = formatter.date(from: dateString) ?? Date()
        } else {
            lastMessageAt = Date()
        }
        
        // Handle createdAt date
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString) ?? Date()
        } else {
            createdAt = Date()
        }
        
        // Handle unreadCount with empty dictionary default
        if let unreadDict = try? container.decode([String: Int].self, forKey: .unreadCount) {
            unreadCount = unreadDict
        } else if let unreadMap = try? container.decode([String: String].self, forKey: .unreadCount) {
            // Handle case where values might be strings
            unreadCount = unreadMap.compactMapValues { Int($0) } 
        } else {
            unreadCount = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(participantIds, forKey: .participants)
        try container.encode(lastMessage, forKey: .lastMessage)
        
        // Format dates as ISO8601 strings
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: lastMessageAt), forKey: .lastMessageAt)
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        
        try container.encode(unreadCount, forKey: .unreadCount)
    }
    
    // Helper method to update participants with full User objects
    mutating func updateParticipants(with users: [User]) {
        let updatedParticipants = participantIds.compactMap { participantId in
            users.first { $0.id == participantId }
        }
        if !updatedParticipants.isEmpty {
            participants = updatedParticipants
        }
    }
} 
