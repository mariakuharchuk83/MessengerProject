//
//  ChatViewController.swift
//  Messenger
//
//  Created by Марія Кухарчук on 26.11.2021.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage

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

struct Media: MediaItem {
   public var url: URL?
   public var image: UIImage?
   public var placeholderImage: UIImage
   public var size: CGSize
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .CustomColors.lightPink
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setUpInputBarButton()
    }
    
    private func setUpInputBarButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 30, height: 30), animated: false)
        button.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        button.onTouchUpInside {[weak self] _ in
            self?.presentInputReact()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 30, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputReact(){
        let actionSheet = UIAlertController(title: "Send meadia", message: "What media would you like to send?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self]_ in
            self?.presentPhotoActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { _ in
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Send photo", message: "Where would you like to get a photo?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self]_ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
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
        
        let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
        
        // send message
        if isNewConversation {
            // create conversation in database
            DataBaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, name: self.title ?? "User") { [weak self] success in
                if success{
                    print("message sent")
                    self?.isNewConversation = false
                    
                    
                } else {
                    print("failed to send")
                }
            }
        } else{
            guard let conversationId = conversationId,
            let name = self.title else {
                return
            }
            // append to existing conversation
            DataBaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("message sent")
                } else {
                    print("failed to send")
                }
            }
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


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default: break
        }
    }
}

extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
        let imageData = image.pngData(),
        let messageID = createMessageId(),
        let conversationID = conversationId,
        let name = self.title,
        let selfSender = selfSender
        else {
            return
        }
        
        let fileName = "photo_message_\(messageID.replacingOccurrences(of: " ", with: "-")).png"
        
        //upload
        StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] result in
            guard let strongSelf = self else {
                return
            }

            switch result{
            case .success(let urlString):
                guard let url = URL(string: urlString),
                let placeholder = UIImage(systemName: "plus.circle")
                else {
                        return
                }
                
                let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .photo(media))
                
                DataBaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                    if success {
                        print("sent photo message")
                    } else {
                        print("failed to send photo message")
                    }
                    
                }
                
            case .failure(let error):
                print("failed to upload message as photo: \(error)")
            }
        }
        
        //send
    }
    
}


//func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

//
//}

extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }
    
}
