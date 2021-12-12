//
//  StorageManager.swift
//  Messenger
//
//  Created by Марія Кухарчук on 28.11.2021.
//

import Foundation
import FirebaseStorage

// The Singleton class defines the `shared` field that lets clients access the
/// unique singleton instance.
/// Singletons should not be cloneable, so that we use `final` expression
final class StorageManager{
    ///     The static field that controls the access to the singleton instance.
    ///     This implementation let you extend the Singleton class while keeping
    ///     just one instance of each subclass around.
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    ///Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: {
            metadata, error in
            guard error == nil else{
                //failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: {
                url, error in
                guard let url = url else {
                    print("Failed to get URL ")
                    completion(.failure(StorageErrors.failedToGetURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download URL returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public enum StorageErrors: Error {
        case failedUpload
        case failedToGetURL
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void){
        let reference =  storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else{
                completion(.failure(StorageErrors.failedToGetURL))
                return
            }
            completion(.success(url))
        })
    }
    
    /// upload image that is going to be send as message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: {
            metadata, error in
            guard error == nil else{
                //failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedUpload))
                return
            }
            
            self.storage.child("message_images/\(fileName)").downloadURL(completion: {
                url, error in
                guard let url = url else {
                    print("Failed to get URL ")
                    completion(.failure(StorageErrors.failedToGetURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download URL returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
}
