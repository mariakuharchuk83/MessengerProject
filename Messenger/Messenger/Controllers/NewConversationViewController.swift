//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Марія Кухарчук on 10.11.2021.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD()

    private let searchBar: UISearchBar={
        let searchBar = UISearchBar()
        searchBar.placeholder = "Type User Name..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultsLable: UILabel = {
        let lable = UILabel()
        lable.isHidden = true
        lable.isHighlighted = true
        lable.text = "No Results"
        lable.textAlignment = .center
        lable.textColor = .CustomColors.lightGreen
        lable.font = .systemFont(ofSize: 21, weight: .medium)
        return lable
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        view.backgroundColor = .CustomColors.strongRed
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done , target: self, action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }
}


extension NewConversationViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
}
