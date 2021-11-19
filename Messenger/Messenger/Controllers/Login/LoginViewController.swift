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

class LoginViewController: UIViewController {

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
            //button.permissions = ["public_profile", "email"]
            button.layer.cornerRadius = 12
            button.layer.masksToBounds = true
            button.style = .standard
           // button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
            return button
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        //Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password){
            [weak self] authResult,
            error in
            
            guard let strongSelf = self
            else{
                return
            }
            
            guard let result = authResult,error == nil
            else{
                print("Error while signing in with email: \(email)")
                return
            }
            let user = result.user
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
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user,
            error in
            
            guard error == nil else {
                return print(error)
                
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
        let facebookRequest = GraphRequest(graphPath: "me", parameters: ["fields": "email, name"])
        
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
                guard let userName = res["name"] as? String,
                      let email = res["email"] as? String else{
                          print("Failed to get email and name from facebook result")
                          return
                      }
                
                //slit name into firstName and lastName
                let nameComponents = userName.components(separatedBy: " ")
                guard nameComponents.count == 2 else{
                    return
                }
                
                let firstName = nameComponents[0]
                let lastName = nameComponents[1]
                
                //check if this user already exists(loged in without facebook)
                DataBaseManager.shared.userExists(with: email, completion: { exists in
                    if !exists {
                        //if not exists, add to database user's credential
                        DataBaseManager.shared.insertUser(with: ChatAppUser(firstname: firstName, lastName: lastName, emailAdress: email))
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
