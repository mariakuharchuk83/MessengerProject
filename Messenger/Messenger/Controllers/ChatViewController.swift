//
//  ChatViewController.swift
//  Messenger
//
//  Created by Марія Кухарчук on 26.11.2021.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType{
  public var sender: SenderType
  public var messageId: String
  public var sentDate: Date
  public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self{
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType{
   public var senderId: String
   public var displayName: String
   public var photoURL: String
}

class ChatViewController: MessagesViewController {

    public var isNewConversation = false
    
    public let otherUserEmail: String
    
    public let conversationId: String?
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        return Sender(senderId: email.parseToSafeEmail(), displayName: "Me", photoURL: "")
    }
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    init(with email: String, id: String?){
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .CustomColors.lightPink
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder() 
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool){
        DataBaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result{
            case .success(let messages):
                guard !messages.isEmpty else{
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
                
                case .failure(let error):
                print("failed to get messages \(error)")
            }
        }
    }

}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = self.selfSender,
        let messageID = createMessageId() else{
            return
        }
        
        print("sanding: \(text)")
        
        // send message
        if isNewConversation {
            // create conversation in database
            let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
            DataBaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, name: self.title ?? "User") { [weak self] success in
                if success{
                    print("message sent")
                } else {
                    print("failed to send")
                }
            }
        } else{
            // append to existing conversation
        }
        
    }
    
    private func createMessageId() -> String? {
        // date, otherUserEmail, senderEmail, randomInt
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let dateString = Self.dateFormatter.string(from: Date())
        let currentUserSafeEmail = currentUserEmail.parseToSafeEmail()
        
        let newIdentifier = "\(otherUserEmail)_\(currentUserSafeEmail)_\(dateString)"
        print("created message id: \(newIdentifier)")
        return newIdentifier
    }
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should do cashed")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
