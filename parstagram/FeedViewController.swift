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
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MessageInputBarDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    
    let myRefreshControl = UIRefreshControl()
    //Create an instance of MessageInputBar
    let commentBar = MessageInputBar()
    
    var showsCommentBar = false
    
    var numberOfPosts: Int = 0
    var posts = [PFObject]()
    
    var selectedPost: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Customize the commentBar
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        //Anytime you have sth that can fire events, => add delegate
        commentBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        //         Do any additional setup after loading the view.
        
        //Allow dismissing the keyboard by dragging it down
        tableView.keyboardDismissMode = .interactive
        
        //This adds an entry with those parameters to the Notification Center, essentially telling it that self wants to observe for notifications with name .keyboardWillHideNotification, and when that notification occurs, the function keyboardWillBeHidden(note:) should be called.
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        loadPosts()
        
        myRefreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
        tableView.refreshControl = myRefreshControl
        
    }
    
    @objc func keyboardWillBeHidden(note: Notification){
        //everytime it's hidden clear that text field
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    //2 Hacking funcs
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool{
        return showsCommentBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadPosts()
        
        //        let query = PFQuery(className: "Posts")
        //                //without the include key, it's just a pointer w/o the actual object, include key makes it goes and
        //                //fetch the actual author in user table
        //                query.includeKeys(["author","comments","comments.author"]) // otherwise, comments only return a pointer to an array
        //                query.limit = 20 // get the last 20
        //
        //                //Find the post object fetched
        //                query.findObjectsInBackground { (posts, error) in
        //                    if posts != nil {
        //        //                self.posts.removeAll()
        //                        self.posts = posts!
        //                        self.tableView.reloadData()
        //                        self.myRefreshControl.endRefreshing()
        //                    }
        //                }
        
    }
    
    @objc func loadPosts(){
        numberOfPosts = 20
        let query = PFQuery(className: "Posts")
        //without the include key, it's just a pointer w/o the actual object, include key makes it goes and
        //fetch the actual author in user table
        query.includeKeys(["author", "comments","comments.author"]) // otherwise, comments only return a pointer to an array
        query.limit = numberOfPosts // get the last 20
        
        //Find the post object fetched
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                //                self.posts.removeAll()
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
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        //Create the comment
        print(text)
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        // which post the comment attaches to
        // didSelect is where posts appears the last time => remember it with a global var selectedPost
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()!
        
        //every post should have an array called comments, and I like you to add this comment to the array
        selectedPost.add(comment, forKey: "comments")
        //Parse over FireBase: Parse save the post => save the comment as well, firebase: manually
        selectedPost.saveInBackground{(success, error) in
            if success {
                print("Comment saved")
            } else {
                print("Error saving comment")
            }
        }
        
        //refresh the view
        self.tableView.reloadData()
        
        //Clear and dismiss the input bar
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #post(1) + #comment
        let post = posts[section]
        //comments could be nil, see Parse Post table
        // ?? (nilcolescing operator): whatever on the left if it's nil, set it equal to the right, in the []
        let comments = (post["comments"] as? [PFObject]) ?? []
        return comments.count + 2
    }
    
    
    //if posts and comments combined together -> complicated. So, we create N sections (N: #posts
    // each section has 1 post and M comments
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        //post cell is the 1st element in the posts array
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            
            
            let user = post["author"] as! PFUser
            cell.usernameLabel.text = user.username
            
            cell.captionLabel.text = post["caption"] as? String
            
            let imageFile = post["image"] as! PFFileObject // has a url
            let urlString = imageFile.url!
            let url = URL(string: urlString)! //create the actual URL
            print(url)
            
            cell.photoView.af_setImage(withURL: url)
            return cell
        } else if indexPath.row <= comments.count { // for the comment
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            let comment = comments[indexPath.row - 1] //because 1st index row is the post
            cell.commentLabel.text = comment["text"] as? String
            
            let user = comment["author"] as! PFUser
            cell.nameLabel.text = user.username
            return cell 
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Everytime the user taps on the tableView, we get a callback here
        //Change indexPath.row -> indexPath.section, otherwise comment only attaches to the first section
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 {
            showsCommentBar = true
            becomeFirstResponder() // cause showsCommentBar to be revaluated
            //raise the keyboard for whoever becomes first responder
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
        }
//        Comment out that fake comment
//                let comment = PFObject(className: "Comments")
//                comment["text"] = "This is a random comment"
//                // which post the comment attachs to
//                comment["post"] = post
//                comment["author"] = PFUser.current()!
//
//                //every post should have an array called comments, and I like you to add this comment to the array
//                post.add(comment, forKey: "comments")
//                //Parse over FireBase: Parse save the post => save the comment as well, firebase: manually
//                post.saveInBackground{(success, error) in
//                    if success {
//                        print("Comment saved")
//                    } else {
//                        print("Error saving comment")
//                    }
//                }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    @IBAction func onLogoutButton(_ sender: Any) {
        PFUser.logOut()
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "loginViewController")
        
        
        let scene = UIApplication.shared.connectedScenes.first
        if let delegate : SceneDelegate = (scene?.delegate as? SceneDelegate) {
            delegate.window?.rootViewController = loginViewController
        }
    }
    
}
