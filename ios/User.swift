//
//  User.swift
//  Runner
//
//  Created by Yogesh Markandey on 21/04/25.
//

import Foundation

struct User: Codable {
    var id: String
    var username: String
    var avatarUrl: String
    var isModerator: Bool

    init(id: String = UUID().uuidString, username: String, avatarUrl: String = Constants.userAvatarUrls[0]) {
        self.id = id
        self.username = username
        self.avatarUrl = avatarUrl
        self.isModerator = true
    }
}
