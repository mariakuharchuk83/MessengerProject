//
//  AppDelegate.swift
//  Messenger
//
//  Created by Марія Кухарчук on 10.11.2021.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn
  
@main
//@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
          
        FirebaseApp.configure()
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        
       // GIDConfiguration.init(clientID: KGoogle.clientID)
        GIDConfiguration.init(clientID: "602604942819-t192sg3mpa44qddh3tefirib6nsa00cs.apps.googleusercontent.com")
      

        return true
    }
          
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        var flag: Bool = false
        //Facebook
         if ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
         ){
             //URL Facebook
             flag = ApplicationDelegate.shared.application(
                app,
                open: url,
                sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                annotation: options[UIApplication.OpenURLOptionsKey.annotation])
         }
        else {
            //URL Google
           flag = GIDSignIn.sharedInstance.handle(url)
        }
        
        return flag
    }
}
    
