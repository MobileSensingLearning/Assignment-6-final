//
//  SkinToneViewController.swift
//  ImageLab
//
//  Created by Brandon McFarland on 11/10/18.
//  Copyright © 2018 Eric Larson. All rights reserved.
//

// import Foundation
let SERVER_URL = "http://192.168.1.206:8000"
//let SERVER_URL = "http://192.168.0.40:8000"
//let SERVER_URL = "http://169.254.224.128:8000"
//let SERVER_URL = "http://169.254.191.8:8000"

import UIKit
import AVFoundation

class SkinToneViewController: UIViewController, URLSessionDelegate, UITextFieldDelegate {
    
    var session = URLSession()
    let operationQueue = OperationQueue()
    var dsid:Int = 0
    var calibrationLabel = "";
    var isPredicting = false;
    var globalPrediction: Any!
    var selectedModel = 0;
    
    @IBOutlet weak var pic0: UIButton!
    @IBOutlet weak var pic1: UIButton!
    @IBOutlet weak var pic2: UIButton!
    @IBOutlet weak var pic3: UIButton!
    @IBOutlet weak var pic4: UIButton!
    @IBOutlet weak var calibrateButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var modelSegmentedControl: UISegmentedControl!
    @IBOutlet weak var cancelPredictionButton: UIButton!
    @IBOutlet weak var dsidInput: UITextField!
    @IBOutlet weak var predictionImg: UIImageView!
    
    
    @IBOutlet weak var predictionPic: UIButton!
    @IBOutlet weak var predictButton: UIButton!
    @IBAction func startCalibration(_ sender: UIButton) {
        self.calibrateButton.isHidden = true
        self.pic0.isHidden = false
        self.pic1.isHidden = false
        self.pic2.isHidden = false
        self.pic3.isHidden = false
        self.pic4.isHidden = false
        self.cancelButton.isHidden = false
        self.modelSegmentedControl.isHidden = false
    }
    
    @IBAction func cancelCalibration(_ sender: UIButton) {
        self.calibrateButton.isHidden = false
        self.pic0.isHidden = true
        self.pic1.isHidden = true
        self.pic2.isHidden = true
        self.pic3.isHidden = true
        self.pic4.isHidden = true
        self.cancelButton.isHidden = true
        self.modelSegmentedControl.isHidden = true
    }
    @IBAction func modelChanged(_ sender: UISegmentedControl) {
        print("INDEX: ", sender.selectedSegmentIndex)
        switch sender.selectedSegmentIndex {
            case 0:
                selectedModel = 0
            case 1:
                selectedModel = 1
        default:
            break
        }
    }
    
    @IBAction func startPrediction(_ sender: UIButton) {
        self.predictionImg.image = (UIImage(named: "timer.png"))
        self.predictionImg.isHidden = false
        self.cancelPredictionButton.isHidden = false
        self.predictButton.isHidden = true
        self.togglePredicting(predictingFlag: true)
    }
    
    @IBAction func cancelPrediction(_ sender: Any) {
        self.predictionImg.isHidden = true
        self.cancelPredictionButton.isHidden = true
        self.predictButton.isHidden = false
    }
    @IBAction func setDsidManually(_ sender: UITextField) {
        self.dsid = Int(sender.text!)!
        
        self.dsidInput.text = sender.text
    }
    
    
    func togglePredicting(predictingFlag: Bool) {
                DispatchQueue.main.async {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                        if (predictingFlag == true) {
                            while ( predictingFlag == true ) {
                                let faceImage = self.bridge.setImage(self.retImageGlobal,
                                                                     withBounds: self.fGlobal[0].bounds, // the first face bounds
                                    andContext: self.videoManager.getCIContext())
                                let ciContext = CIContext()
                                let cgImage = ciContext.createCGImage(faceImage!, from: faceImage!.extent)
                                self.testImage.image = UIImage.init(cgImage: cgImage!)
                                let copyImage = self.testImage.image
                                let copyImageData:NSData = UIImagePNGRepresentation(copyImage!)! as NSData
                                let strBase64 = copyImageData.base64EncodedString(options: .lineLength64Characters)
                                //print(strBase64)
                                self.getPrediction([strBase64])
                                if (self.globalPrediction != nil ) {
                                    break
                                }
                            }
                        }
                    })
                }
                // delay
    }
    
    
    //MARK: Class Properties
    var videoManager:VideoAnalgesic! = nil
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    var fGlobal:[CIFaceFeature] = [];
    var retImageGlobal:CIImage = CIImage()
    var testImage: UIImageView = UIImageView()
    
    // Capture image
    @IBAction func actuallyCapture(_ sender: UIButton) {
        switch sender {
        case pic0:
            self.calibrationLabel = "light"
        case pic1:
            self.calibrationLabel = "medium light"
        case pic2:
            self.calibrationLabel = "medium"
        case pic3:
            self.calibrationLabel = "medium dark"
        case pic4:
            self.calibrationLabel = "dark"
        default:
            break
        }
        self.bridge.setTransforms(self.videoManager.transform)
        let faceImage = self.bridge.setImage(retImageGlobal,
                                             withBounds: fGlobal[0].bounds, // the first face bounds
            andContext: self.videoManager.getCIContext())
        
        if(faceImage != nil) {
            print("face image is not null")
            
            DispatchQueue.main.async {
                let ciContext = CIContext()
                let cgImage = ciContext.createCGImage(faceImage!, from: faceImage!.extent)
                self.testImage.image = UIImage.init(cgImage: cgImage!)
                let copyImage = self.testImage.image
                let copyImageData:NSData = UIImagePNGRepresentation(copyImage!)! as NSData
                let strBase64 = copyImageData.base64EncodedString(options: .lineLength64Characters)
                //print(strBase64)
                self.sendFeatures([strBase64], withLabel: self.calibrationLabel)
                self.makeModel2()
            }
        }
    }
    
    //@IBOutlet var imageCapture: UIView!
    //MARK: Outlets in view
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        self.bridge.loadHaarCascade(withFilename: "nose")
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow,CIDetectorTracking:true] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                   context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig,
                                  delegate: self,
                                  delegateQueue:self.operationQueue)
        
        dsid = 1
        self.dsidInput.text = String(dsid)
    }
    
    func sendFeatures(_ array:[String], withLabel label:String){
        
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        let postUrl = URL(string: "\(baseURL)")
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array,
                                       "label":"\(label)",
                                        "dsid":self.dsid,
                                        "modelName": selectedModel]
        
        print(jsonUpload)
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    if(error != nil){
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                print(jsonDictionary["feature"]!)
                                                                        print(jsonDictionary["label"]!)
                                                                    }
                                                                    
        })
        
        postTask.resume() // start the task
    }
    
    func getPrediction(_ array:[String]){
        let baseURL = "\(SERVER_URL)/PredictOne"
        let postUrl = URL(string: "\(baseURL)")

        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)

        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":array, "dsid":self.dsid]


        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)

        request.httpMethod = "POST"
        request.httpBody = requestBody

        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    if(error != nil){
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)

                                                                        let labelResponse = jsonDictionary["prediction"]!
                                                                        print(labelResponse)
                                                                        self.displayLabelResponse(labelResponse as! String)
                                                                        self.globalPrediction = labelResponse
//                                                                        self.displayLabelResponse(labelResponse as! String)

                                                                    }

        })

        postTask.resume() // start the task
    }

    @IBAction func makeModel(_ sender: AnyObject) {
        
        // create a GET request for server to update the ML model with current data
        let baseURL = "\(SERVER_URL)/UpdateModel"
        let query = "?dsid=\(self.dsid)"
        
        let getUrl = URL(string: baseURL+query)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    // handle error!
                                                                    if (error != nil) {
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                        
                                                                        if let resubAcc = jsonDictionary["resubAccuracy"]{
                                                                            print("Resubstitution Accuracy is", resubAcc)
                                                                        }
                                                                    }
                                                                    
        })
        
        dataTask.resume() // start the task
        
    }
    
    func makeModel2() {
        // create a GET request for server to update the ML model with current data
        let baseURL = "\(SERVER_URL)/UpdateModel"
        let query = "?dsid=\(self.dsid)&modelName=\(self.selectedModel)"
        
        let getUrl = URL(string: baseURL+query)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    // handle error!
                                                                    if (error != nil) {
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)
                                                                        
                                                                        if let resubAcc = jsonDictionary["resubAccuracy"]{
                                                                            print("Resubstitution Accuracy is", resubAcc)
                                                                        }
                                                                    }
                                                                    
        })
        
        dataTask.resume() // start the task
    }
    
    //MARK: JSON Conversion Functions
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertDataToDictionary(with data:Data?)->NSDictionary{
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: NSDictionary =
                try JSONSerialization.jsonObject(with: data!,
                                                 options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            return jsonDictionary
            
        } catch {
            print("json error: \(error.localizedDescription)")
            return NSDictionary() // just return empty
        }
    }
    
    func processImage(inputImage:CIImage) -> CIImage{
        // detect faces
        let f = getFaces(img: inputImage)
        // if no faces, just return original image
        if f.count == 0 { return inputImage }
        
        fGlobal = f
        
        let retImage = inputImage
        retImageGlobal = retImage
        return retImage
    }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func displayLabelResponse(_ response:String){
        
        DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                switch response {
                case "[u'light']":
                    self.predictionImg.image = (UIImage(named: "light_skin_tone.png"))
                case "[u'medium light']":
                    self.predictionImg.image = (UIImage(named: "medium_light_skin_tone.png"))
                case "[u'medium']":
                    self.predictionImg.image = (UIImage(named: "medium_skin_tone.png"))
                case "[u'medium dark']":
                    self.predictionImg.image = (UIImage(named: "medium_dark_skin_tone.png"))
                case "[u'dark']":
                    self.predictionImg.image = (UIImage(named: "dark_skin_tone.png"))
                default:
                    print("Unknown")
                    break
                }
            })
        }
    }
    
}
