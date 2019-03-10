//
//  ViewController.swift
//  Flower
//
//  Created by Eldon Jiang on 2019-03-09.
//  Copyright © 2019 Eldon Jiang. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikiURL = "https://en.wikipedia.org/w/api.php"

    @IBOutlet weak var imgView: UIImageView!
    
    @IBOutlet weak var info: UILabel!
    
    let imgPicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imgPicker.delegate = self
        imgPicker.allowsEditing = true
        imgPicker.sourceType = .camera
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImg = info[.editedImage] as? UIImage {
            imgView.image = pickedImg
        }
        imgPicker.dismiss(animated: true, completion: nil)
    }

    @IBAction func detectPressed(_ sender: UIButton) {
        guard let ciImg = CIImage(image: imgView.image!) else {
            fatalError("Erron in converting UIImage to CIImage!")
        }
        detect(img: ciImg)
    }
    
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imgPicker, animated: true, completion: nil)
    }
    
    func detect(img:CIImage) {
        guard let imgModel = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Erron in loaidng CoreML model!")
        }
        let request = VNCoreMLRequest(model: imgModel) { (request, error) in
            guard let results = request.results?.first as? VNClassificationObservation else {
                fatalError("Error in loading results!")
            }
            let alert = UIAlertController(title: "Seems like...", message: results.identifier.capitalized, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OJBK", style: .default, handler: { (action) in
                self.navigationItem.title = results.identifier.capitalized
                self.getInfo(flowerName: results.identifier.capitalized)
            })
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        let handler = VNImageRequestHandler(ciImage: img)
        
        do{
            try handler.perform([request])
        } catch {
            fatalError(error as! String)
        }
    }
    
    func getInfo(flowerName: String) {
        let params : [String:String] = [
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
        
        Alamofire.request(wikiURL, method: .get, parameters: params).responseJSON{
            response in
            if response.result.isSuccess {
                let flowerData : JSON = JSON(response.result.value!)
                let pageId = flowerData["query"]["pageids"][0].stringValue
                if pageId == "-1" {
                    self.info.text = "Information unavailable for this flower..."
                } else {
                    let description = flowerData["query"]["pages"][pageId]["extract"].stringValue
                    self.info.text = description
                    let imgURL = flowerData["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                    self.imgView.sd_setImage(with: URL(string: imgURL))
                }
            } else {
                self.info.text = "Information unavailable for this flower..."
            }
        }
    }
}

