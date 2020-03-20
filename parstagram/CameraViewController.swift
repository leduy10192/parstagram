//
//  CameraViewController.swift
//  parstagram
//
//  Created by Duy Le on 3/19/20.
//  Copyright © 2020 Duy Le. All rights reserved.
//

import UIKit
import AlamofireImage
import Parse
class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var commentField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func onSubmit(_ sender: Any) {
        // create a PFObjects for pet dict, Parse will create a table Pet for you on the fly
        let post = PFObject(className: "Posts")
        
        //Define the schema, Parse will create those column for these dict keys
        post["caption"] = commentField.text
        post["author"] = PFUser.current()! //For the loggedin Owner
        
        //Store photo birary URL
        let imageData = imageView.image!.pngData()
        // save as binary in a separate table
        let file = PFFileObject(name: "image.png", data: imageData!)
        //save the URL reference to the binary
        post["image"] = file
        
        //Every PFObj has the ability to save itself
        post.saveInBackground { (success,error) in
            if success {
                // the picture will fade away
                self.dismiss(animated: true, completion:  nil)
                print("saved!")
            }else{
                print("error!")
            }
        }
    }
    
    @IBAction func onCameraButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        //Check if the camera is avaiblabe, otherwise the app will crash{
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            //if available, open up the camera
            picker.sourceType = .camera
            
            //if simulator, camera not available, use photo library
            picker.sourceType = .photoLibrary
        }
        
        present(picker, animated: true, completion: nil)
    }
    
    
    // For the image to show up, add this func
    //This func will hand you back the dict that has the image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as! UIImage
        // This image is very large, Heroku has a limit of size image can upload -> import Alamofire and resize it
        let size = CGSize(width: 300, height: 300)
        
        let scaledImage = image.af_imageScaled(to: size)
        
        imageView.image = scaledImage
        
        //dismiss that camera viw
        dismiss(animated: true, completion: nil)
        
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
