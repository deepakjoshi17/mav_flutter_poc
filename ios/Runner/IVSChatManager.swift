//
//  IVSChatManager.swift
//  Runner
//
//  Created by Yogesh Markandey on 21/04/25.
//

import Foundation
import AmazonIVSChatMessaging

class IVSChatManager: ObservableObject {

    private var chatRoom: ChatRoom?
    private var chatToken: String = ""
    private var awsRegion: String = ""
    
    @Published var isAuthorised: Bool = false
    @Published var messages: [AnyHashable] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var infoMessage: String?
    
    func initializeManager(region: String){
        awsRegion = region
    }

    func updateToken(token: String){
        chatToken = token
    }
    
    func retriveChatToken() async -> ChatToken {
        let chatToken = ChatToken(
           token: chatToken,
           tokenExpirationTime: nil, // this is optional
           sessionExpirationTime: nil // this is optional
        )
        
        return chatToken
    }

    // Connect to the chat room using token and endpoint
    func connectToChatRoom() {
        if chatRoom?.state == .connected {
            return
        }
        Task(priority: .background){
            if chatRoom?.state != .disconnected {
                chatRoom?.disconnect()
            }
                       
            if chatRoom != nil {
                chatRoom?.delegate = nil
                chatRoom = nil
            }
            let chatRoom = ChatRoom(
               awsRegion: awsRegion){
                   return ChatToken(
                    token: self.chatToken,
                    tokenExpirationTime: nil, // this is optional
                    sessionExpirationTime: nil // this is optional
                )
            }
            chatRoom.delegate = self
            try await chatRoom.connect()
        }
    }

    func sendMessage(_ message: String, type: MessageType) {
            var content = ""
            var attributes: Chat.Attributes = [:]
            switch type {
                case .message:
                    content = message
                    attributes = ["message_type": "MESSAGE"]
                case .sticker:
                    content = "Sticker"
                    attributes = ["message_type": "STICKER",
                                  "sticker_src": "\(message)"]
            }

            chatRoom?.sendMessage(with: SendMessageRequest(content: content, attributes: attributes),
                                  onSuccess: { _ in
                print("Sent Sucessfully : \(content)")
                },
                              onFailure: { error in
                print("❌ error sending message: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            })
        }
    
    func kick(user id: String) {
            chatRoom?.disconnectUser(with: DisconnectUserRequest(id: id, reason: "Kicked by moderator"), onSuccess: { _ in
                DispatchQueue.main.async {
                    self.successMessage = "User kicked"
                }
            })
        }
}


extension IVSChatManager: ChatRoomDelegate {
    func roomDidConnect(_ room: ChatRoom) {
        DispatchQueue.main.async {
            self.isAuthorised = true
            if self.isAuthorised {
                self.messages.append(SuccessMessage(text: "Connected to chat"))
            }
        }
    }

    func roomDidDisconnect(_ room: ChatRoom) {
        DispatchQueue.main.async {
            if self.isAuthorised {
                self.messages.append(ErrorMessage(text: "Disconnected from chat", details: ""))
            }
            self.isAuthorised = false
        }
    }

    func room(_ room: ChatRoom, didDisconnect user: DisconnectedUser) {
        // Remove local messages from the removed user
        messages.forEach { msg in
            guard let message = msg as? Message else {
                return
            }
            DispatchQueue.main.async {
                if message.sender.id == user.userId,
                   let index = self.messages.firstIndex(where: { obj in
                       if let msg = obj as? Message {
                           return msg.id == message.id
                       } else if let msg = obj as? ErrorMessage {
                           return msg.id == message.id
                       } else if let msg = obj as? SuccessMessage {
                           return msg.id == message.id
                       } else {
                           return false
                       }
                   }) {

                    if index < self.messages.count {
                        self.messages.remove(at: index)
                    }
                }
            }
        }
    }

    func room(_ room: ChatRoom, didDelete message: DeletedMessage) {
        // Remove local message
        if let index = messages
            .firstIndex(where: { obj in
                if let msg = obj as? Message {
                    return msg.id == message.messageID
                }
                return false
            }) {
            DispatchQueue.main.async {
                self.messages.remove(at: index)
            }
        } else {
            print("❌ Could not remove local message, reason: no message found (id: \(message.messageID))")
        }
    }

    func room(_ room: ChatRoom, didReceive message: ChatMessage) {
        DispatchQueue.main.async {
            let msg = Message(
                id: message.id,
                objectType: .message,
                type: MessageType(rawValue: message.attributes?["message_type"] ?? "") ?? .message,
                requestId: message.requestId ?? UUID().uuidString,
                content: message.content,
                attributes: Message.Attributes(type: MessageType(rawValue: message.attributes?["message_type"] ?? "") ?? .message,
                                               stickerSrc: message.attributes?["sticker_src"] ?? ""),
                sendTime: "\(message.sendTime)",
                sender: User(id: message.sender.userId,
                             username: message.sender.attributes?["username"] ?? "",
                             avatarUrl: message.sender.attributes?["avatar"] ?? ""))
            self.messages.append(msg)
        }
    }

    func room(_ room: ChatRoom, didReceive event: ChatEvent) {
        print("⚠️ didReceive event \(event)")
    }
}
