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
            completion(true)
        })
    }
}

struct ChatAppUser{
    let firstname: String
    let lastName: String
    let emailAdress: String
    
    var safeEmail: String {
        return emailAdress.parseToSafeEmail()
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}


