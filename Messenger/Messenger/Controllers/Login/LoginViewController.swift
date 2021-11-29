//
//  LoginViewController.swift
//  Messenger
//
//  Created by Марія Кухарчук on 10.11.2021.
//

import UIKit
import FirebaseAuth
import Firebase
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .light)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = UIColor.CustomColors.lightPink
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let loginButtonFB: FBLoginButton = {
            let button = FBLoginButton()
            button.permissions = ["public_profile", "email"]
            button.layer.cornerRadius = 12
            button.layer.masksToBounds = true
            button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
            return button
    }()

    private let loginButtonGoogle: GIDSignInButton = {
            let button = GIDSignInButton()
            button.layer.cornerRadius = 12
            button.layer.masksToBounds = true
            button.style = .standard
            return button
    }()

    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else{
                return
            }
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        loginButtonFB.delegate = self
        loginButtonGoogle.addTarget(self, action:  #selector(loginGoogle), for: .touchUpInside)
        
        /// Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(loginButtonFB)
        scrollView.addSubview(loginButtonGoogle)
    }
    
    deinit{
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/4
        
        imageView.frame = CGRect(x: (scrollView.width - size)/2, y: 35, width: size, height: size)
        
        emailField.frame = CGRect(x: 30, y: imageView.buttom+20, width: scrollView.width-60, height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.buttom+20, width: scrollView.width-60, height: 52)
        
        loginButton.frame = CGRect(x: 30, y: passwordField.buttom+20, width: scrollView.width-60, height: 52)
        
        loginButtonFB.frame = CGRect(x: 30, y: loginButton.buttom+20, width: scrollView.width-60, height: 52)
        
        loginButtonGoogle.frame = CGRect(x: 30, y: loginButtonFB.buttom+20, width: scrollView.width-60, height: 52)
        
    }
    
    @objc private func loginButtonTapped(){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else{
                  alertUserLoginError()
                  return
              }
        
        spinner.show(in: view)
        
        //Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password){
            [weak self] authResult,
            error in
            
            guard let strongSelf = self
            else{
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: true)
            }
            
            guard let result = authResult,error == nil
            else{
                print("Error while signing in with email: \(email)")
                return
            }
            let user = result.user
            
            UserDefaults.standard.set(email, forKey: "email")
            
            print("Signed In user: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Oops..", message: "Please enter all information correctly", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @objc private func loginGoogle(){
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
       //GIDSignIn.sharedInstance.sign
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [weak self] user,
            error in
            
            guard error == nil else {
                return print(error!)
                
            }

                   guard let authentication = user?.authentication,
                            let idToken = authentication.idToken  else {
                     let error = NSError(
                       domain: "GIDSignInError",
                       code: -1,
                       userInfo: [
                         NSLocalizedDescriptionKey: "Unexpected sign in result: required authentication data is missing.",
                       ]
                     )
                     return print(error)
                   }
            
                guard let user = user else { return }

                let email = user.profile!.email

                let firstName = user.profile!.givenName!
                let lastName = user.profile!.familyName!

                let pictureURL = user.profile?.imageURL(withDimension: 320)
            
            UserDefaults.standard.set(email, forKey: "email")
            
            DataBaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    //if not exists, add to database user's credential
                    let chatUser = ChatAppUser(firstname: firstName, lastName: lastName, emailAddress: email)
                    DataBaseManager.shared.insertUser(with: chatUser, completion: {success in
                        if success{
                            
                            print("Downloading data from Google")
                            
                            URLSession.shared.dataTask(with: pictureURL!, completionHandler: {
                                data, _, _ in
                                guard let data = data else{
                                    print("Failed to get data from Google")
                                    return
                                }
                                
                                print("got data from Google, uploading.. ")
                                //upload image
                                
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                        print(downloadURL)
                                    case .failure(let error): print("Storage Manager error: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    })
                }
                
            })
                
            

            
                   let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                                  accessToken: authentication.accessToken)
            
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {
                [weak self] authResult,
                error in
                
                guard let strongSelf = self
                else{
                    return
                }
                
                guard authResult != nil,error == nil
                else{
                    if let error = error {
                        print("Error while signing in with google: \(error) ")
                    }
                    return
                }
                
                print("User logged in with google.")
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
            
            
        }
    }
}



extension LoginViewController : UITextFieldDelegate, LoginButtonDelegate {
    //work with swiping across fields
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
    
    
    //facebool login
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        //unwrap token from FB
        guard let token = result?.token?.tokenString
        else{
            print("User failed to log in with Facebook")
            return
        }
        
        // request obj to get email and name
        let facebookRequest = GraphRequest(graphPath: "me", parameters: ["fields":
                                                                            "email, first_name, last_name, picture.type(large)"])
        
        //do request and get needed data
        facebookRequest.start(completion: { (connection, result, error) -> Void in
            if (error) != nil {
                print("Error: \(String(describing: error))")
            }
            else {
                //get all data to some dictionary
                guard let res = result as? [String: Any] else {
                    print("facebook Did not allowed loading email, please set that while updating profile.")
                    return
                }
                
                
                //get our properties from dictionary
                guard let firstName = res["first_name"] as? String,
                      let lastName = res["last_name"] as? String,
                      let email = res["email"] as? String,
                      let picture = res["picture"] as? [String: Any],
                      let data = picture["data"] as? [String: Any],
                      let pictureURL = data["url"] as? String else{
                          print("Failed to get email and name from facebook result")
                          return
                      }
                
                UserDefaults.standard.set(email, forKey: "email")
                //check if this user already exists(loged in without facebook)
                DataBaseManager.shared.userExists(with: email, completion: { exists in
                    if !exists {
                        //if not exists, add to database user's credential
                        let chatUser = ChatAppUser(firstname: firstName, lastName: lastName, emailAddress: email)
                        DataBaseManager.shared.insertUser(with: chatUser, completion: {success in
                            if success{
                                
                                guard let url = URL(string: pictureURL) else{
                                    return
                                }
                                
                                print("Downloading data from FB")
                                
                                URLSession.shared.dataTask(with: url, completionHandler: {
                                    data, _, _ in
                                    guard let data = data else{
                                        print("Failed to get data from FB")
                                        return
                                    }
                                    
                                    print("got data from FB, uploading.. ")
                                    
                                    //upload image
                                    let fileName = chatUser.profilePictureFileName
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                        switch result {
                                        case .success(let downloadURL):
                                            UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                            print(downloadURL)
                                        case .failure(let error): print("Storage Manager error: \(error)")
                                        }
                                    })
                                }).resume()
                            }
                        } )
                    }
                })
            }
            
            //data of the user
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            print("credential: \(credential)")
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {
                [weak self] authResult,
                error in
                
                guard let strongSelf = self
                else{
                    return
                }
                
                guard authResult != nil,error == nil
                else{
                    if let error = error {
                        print("Error while signing in with facebook: \(error) ")
                    }
                    return
                }
                
                print("User logged in with facebook.")
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }

    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //unnecessary
    }
}
