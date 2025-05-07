//
//  ChatMessage.swift
//  Chapro
//
//  Created by そらだい on 2025/04/28.
//

import Foundation

struct ChatMessage: Identifiable, Codable {
    var id: Int
    var threadId: Int
    var seq: Int
    var type: String
    var message: String
    var createAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case threadId = "thread_id"
        case seq
        case type
        case message
        case createAt = "create_at"
    }
    
    var compositeId: String {
        "\(threadId)-\(id)-\(seq)"
    }
}
