//  ViewController.swift
//  SeeFood

//  Created by Hendy Christian on 08/10/20.

import UIKit
import CoreML
import Vision

import Alamofire
import SwiftyJSON

import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate,
                        UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var label: UILabel!
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController();
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        imagePicker.delegate = self
        
        // This bring UIimagePicker that contain camera module. To allow user take image
        imagePicker.sourceType = .camera
        
        //Let the user to edit [Crop] the image
        imagePicker.allowsEditing = true
        
    }
    
    // Overview. An image picker controller manages user interactions and delivers the results of those
     func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        //Jika user mengclick image and Use Photo sebagai UIImage
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage.rawValue] as? UIImage {
            
//            imageView.image = userPickedImage
            
            // Convert userPickedImage into CIImage
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            detect(image: convertedCIImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
    
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Fail'Inceptionv3()' ")
        }
        
        let request = VNCoreMLRequest(model: model) { ( request , error ) in
            
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image.")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        // Handler dibuat untuk memproses requestnya.
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }catch {
            print(error)
        }
        
    }
    
    //API Method
    func requestInfo(flowerName: String){
        
        let parameters: [String:String] = [
        
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            
        ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON{ (response) in
            
            if response.result.isSuccess{
                    print("Got the wikipedia info.")
                    print(response)
                
                let flowerJSON : JSON = JSON(response.result.value!)
                
                let pageid = flowerJSON["query"]["pageid"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                // Update imageView user sd_setImage with URL as a stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL) )
                    self.label.text = flowerDescription
                
            }
        }
    }
    
    //Pada saat Camera BarItem di click
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        // User dapat membuka camera atau select picture from album
        present( imagePicker , animated: true, completion: nil)
        
    }
    

}
