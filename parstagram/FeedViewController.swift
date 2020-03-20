//
//  FeedViewController.swift
//  parstagram
//
//  Created by Duy Le on 3/19/20.
//  Copyright © 2020 Duy Le. All rights reserved.
//

import UIKit
import Parse
import AlamofireImage

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    
    let myRefreshControl = UIRefreshControl()
    
    var numberOfPosts: Int = 0
    var posts = [PFObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        loadPosts()
        
        myRefreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
        tableView.refreshControl = myRefreshControl
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadPosts()
        
    }
    
    @objc func loadPosts(){
        numberOfPosts = 20
        let query = PFQuery(className: "Posts")
        //without the include key, it's just a pointer w/o the actual object, include key makes it goes and
        //fetch the actual author in user table
        query.includeKey("author")
        query.limit = numberOfPosts // get the last 20
        
        //Find the post object fetched
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                self.posts.removeAll()
                self.posts = posts!
                self.tableView.reloadData()
                self.myRefreshControl.endRefreshing()
            }
        }
    }
    
//    func loadMorePosts(){
//        numberOfPosts = numberOfPosts + 2
//        let query = PFQuery(className: "Posts")
//        //without the include key, it's just a pointer w/o the actual object, include key makes it goes and
//        //fetch the actual author in user table
//        query.includeKey("author")
//        query.limit = numberOfPosts // get the last 20
//
//        //Find the post object fetched
//        query.findObjectsInBackground { (posts, error) in
//            if posts != nil {
//                self.posts.removeAll()
//                self.posts = posts!
//                self.tableView.reloadData()
//            }
//        }
//    }
//
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if indexPath.row + 1 == posts.count {
//            loadMorePosts()
//        }
//    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        let post = posts[indexPath.row]
        
        let user = post["author"] as! PFUser
        cell.usernameLabel.text = user.username
        
        cell.captionLabel.text = post["caption"] as? String
        
        let imageFile = post["image"] as! PFFileObject // has a url
        let urlString = imageFile.url!
        let url = URL(string: urlString)! //create the actual URL
        print(url)
        
        cell.photoView.af_setImage(withURL: url)
        return cell
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
