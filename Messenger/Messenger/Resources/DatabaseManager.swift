//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Марія Кухарчук on 15.11.2021.
//

import Foundation
import FirebaseDatabase

/// The Singleton class defines the `shared` field that lets clients access the
/// unique singleton instance.
/// Singletons should not be cloneable, so that we use `final` expression
final class DataBaseManager{
    
///     The static field that controls the access to the singleton instance.
///     This implementation let you extend the Singleton class while keeping
///     just one instance of each subclass around.
    static let shared = DataBaseManager()
    
    private let database = Database.database().reference()
    
//    static func safeEmail(emailAddress: String) -> String {
//        return emailAddress.parseToSafeEmail()
//    }
    
}

//MARK: - Account Management

extension DataBaseManager{
    
    public func userExists(with email: String, completion: @escaping ((Bool)->Void) ) {
        
        let safeEmail = email.parseToSafeEmail()
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil
            else{
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    ///inserts new user to datadase
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void ) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstname,
            "last_name": user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else{
                print("Failed to write to db")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]]{
                    //append to user dictionary
                    let newElement = [
                        "name": user.firstname + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    
                    usersCollection.append(newElement)
                    self.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                    
                } else {
                    //create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstname + " " + user.lastName,
                            "email": user.safeEmail
                        ],
                    ]
                    
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
                
            }
            
            
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value) { snaphot in
            guard let value = snaphot.value as? [[String:String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error{
        case failedToFetch
    }
}

//MARK: - Sending messages / conversations
extension DataBaseManager  {
    
    /*
     users => [
     [
     "name":
     "safe_email":
     ],
     [
     "name":
     "safe_email":
     ]
     ]
     */
    
    /// 1. Create a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, name: String, completion: @escaping (Bool) -> Void ){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = currentEmail.parseToSafeEmail()
        
        //reference to cuurent user
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value) { [weak self] snaphot in
            guard var userNode = snaphot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
                break
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": "Self",
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            //updaterecipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observe(.value) {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversationID)
                } else {
                    //create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
                
            }
            
            // update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //conversation array exists for current user
                //you should append
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                }
            } else{
                //conversation array does't exist for current user => create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) {[weak self] error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                }
            }
            
        }
        
    }
    
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void ) {
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        let conversationID = "conversation_\(firstMessage.messageId)"
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
            break
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId ,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail.parseToSafeEmail(),
            "is_read": false,
            "name": name
        ]
        
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// 2. Return all conversations of the user with email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void ){
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else{
                          return nil
                      }
                let latestMessageObj = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObj)
            }
            completion(.success(conversations))
        }
        
    }
    
    /// 3. Return all messages of the conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void ){
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap { dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageId = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return nil
                }
                
                let sender = Sender(senderId: senderEmail, displayName: name, photoURL: "")
                
                
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: .text(content))
                
            }
            completion(.success(messages))
        }
        
    }
    
    /// 4. Add message to existing conversation
    public func sendMessage(to conversation: String, massage: Message, completion: @escaping (Bool) -> Void ){
        
    }
    
}

struct ChatAppUser{
    let firstname: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        return emailAddress.parseToSafeEmail()
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}


