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


