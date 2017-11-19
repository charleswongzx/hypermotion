//
//  ViewController.swift
//  Measure
//
//  Created by levantAJ on 8/9/17.
//  Copyright © 2017 levantAJ. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

final class ViewController: UIViewController {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var targetImageView: UIImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var meterImageView: UIImageView!
    @IBOutlet weak var resetImageView: UIImageView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    
    @IBOutlet weak var rotatableSwitch: UISwitch!
    @IBOutlet weak var fragileSwitch: UISwitch!
    @IBOutlet weak var stackableSwitch: UISwitch!
    
    fileprivate lazy var session = ARSession()
    fileprivate lazy var sessionConfiguration = ARWorldTrackingConfiguration()
    fileprivate lazy var isMeasuring = false;
    fileprivate lazy var vectorZero = SCNVector3()
    fileprivate lazy var startValue = SCNVector3()
    fileprivate lazy var endValue = SCNVector3()
    fileprivate lazy var lines: [Line] = []
    fileprivate var currentLine: Line?
    fileprivate lazy var unit: DistanceUnit = .centimeter
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        
        rotatableSwitch.isOn = false
        fragileSwitch.isOn = false
        stackableSwitch.isOn = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if lines.count < 3 {
            resetValues()
            isMeasuring = true
            targetImageView.image = UIImage(named: "targetGreen")
        }
        else {
            messageLabel.text = "3 measurements max, please submit or undo"
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMeasuring = false
        targetImageView.image = UIImage(named: "targetWhite")
        if let line = currentLine {
            lines.append(line)
            currentLine = nil
            resetButton.isHidden = false
            resetImageView.isHidden = false
        }
        if lines.count == 3 {
            submitButton.isHidden = false
        }
        else {
            submitButton.isHidden = true
        }
        undoButton.isHidden = false
        if lines.count == 0 {
            messageLabel.text = "Measure width of cargo"
        }
        else if lines.count == 1 {
            messageLabel.text = "Measure depth of cargo"
        }
        else if lines.count == 2 {
            messageLabel.text = "Measure height of cargo"
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            self?.detectObjects()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        messageLabel.text = "Error occurred"
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        messageLabel.text = "Interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        messageLabel.text = "Interruption ended"
    }
}

// MARK: - Users Interactions

extension ViewController {
//    @IBAction func meterButtonTapped(button: UIButton) {
//        let alertVC = UIAlertController(title: "Settings", message: "Please select distance unit options", preferredStyle: .actionSheet)
//        alertVC.addAction(UIAlertAction(title: DistanceUnit.centimeter.title, style: .default) { [weak self] _ in
//            self?.unit = .centimeter
//        })
//        alertVC.addAction(UIAlertAction(title: DistanceUnit.inch.title, style: .default) { [weak self] _ in
//            self?.unit = .inch
//        })
//        alertVC.addAction(UIAlertAction(title: DistanceUnit.meter.title, style: .default) { [weak self] _ in
//            self?.unit = .meter
//        })
//        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        present(alertVC, animated: true, completion: nil)
//    }
    
    @IBAction func resetButtonTapped(button: UIButton) {
        resetButton.isHidden = true
        resetImageView.isHidden = true
        submitButton.isHidden = true
        undoButton.isHidden = true
        rotatableSwitch.isOn = false
        fragileSwitch.isOn = false
        stackableSwitch.isOn = false
        messageLabel.text = "Measure width of cargo"
        for line in lines {
            line.removeFromParentNode()
        }
        lines.removeAll()
    }
    
    func reset(){
        resetButton.isHidden = true
        resetImageView.isHidden = true
        submitButton.isHidden = true
        undoButton.isHidden = true
        rotatableSwitch.isOn = false
        fragileSwitch.isOn = false
        stackableSwitch.isOn = false
        messageLabel.text = "Measure width of cargo"
        for line in lines {
            line.removeFromParentNode()
        }
        lines.removeAll()
    }
    
    @IBAction func undoButtonTapped(button: UIButton) {
        submitButton.isHidden = true
        let line = lines.popLast()
        line?.removeFromParentNode()
        if lines.count == 0 {
            resetButton.isHidden = true
            resetImageView.isHidden = true
            undoButton.isHidden = true
        }
        if lines.count == 0 {
            messageLabel.text = "Measure width of cargo"
        }
        else if lines.count == 1 {
            messageLabel.text = "Measure height of cargo"
        }
        else if lines.count == 2 {
            messageLabel.text = "Measure depth of cargo"
        }
    }
    
    @IBAction func submitButtonTapped(button: UIButton) {
        let message = NSLocalizedString("Width: " + String(format: "%.2f", lines[0].finalDistance()*100) + "cm\nHeight: " + String(format: "%.2f", lines[1].finalDistance()*100) + "cm\nDepth: " + String(format: "%.2f", lines[2].finalDistance()*100) + "cm",
                                        comment: "Ask user whether they want to upload data")
        let alertController = UIAlertController(title: "Upload data?", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Yes"),
                                                style: .default,
                                                handler: { (action:UIAlertAction!) -> Void in
                                                    self.uploadData(self.lines[0].finalDistance()*100, self.lines[1].finalDistance()*100, self.lines[2].finalDistance()*100, identifier: (alertController.textFields?[0].text)!, weight: (alertController.textFields?[1].text)!)
                                                    self.reset()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "No"),
                                                style: .cancel,
                                                handler: { (action:UIAlertAction!) -> Void in
                                                    return
        }))
        alertController.addTextField { (textField) in
            textField.placeholder = "Item Identifier"
            textField.keyboardType = .default
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Weight (kg)"
            textField.keyboardType = .numberPad
        }
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func uploadData(_ measure1: Float,_ measure2: Float,_ measure3: Float, identifier: String, weight: String){
        
        //print(identifier)
        //print(measure1)
        
        let serviceUrl = URL(string:"http://192.168.43.153:5000/upload")
        var request = URLRequest(url: serviceUrl!)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["id": identifier,"name": identifier, "weight": weight, "dim1": measure1, "dim2": measure2, "dim3": measure3, "rotatable": self.rotatableSwitch.isOn, "fragile": self.fragileSwitch.isOn, "stackable": self.stackableSwitch.isOn] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = TimeInterval(10)
            configuration.timeoutIntervalForResource = TimeInterval(10)
            let session = URLSession(configuration: configuration)
            let reqsession = session.dataTask(with: request) {
                (data, response, err) in
                guard err == nil else {
                    print(err?.localizedDescription as Any)
                    let message = NSLocalizedString("An error occured during the upload.",
                                                    comment: "Error")
                    let alertController = UIAlertController(title: "Upload to Cloud", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Alert OK button"),
                                                            style: .`default`,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                
                let httpResponse = response as! HTTPURLResponse
                print(httpResponse)
                
                let statusCode = httpResponse.statusCode
                
                if statusCode == 200{
                    let message = NSLocalizedString("Success",
                                                    comment: "Success")
                    let alertController = UIAlertController(title: "Packery Upload", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Alert OK button"),
                                                            style: .`default`,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                else{
                    let message = NSLocalizedString("An error occured during the upload.",
                                                    comment: "Error")
                    let alertController = UIAlertController(title: "Packery", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Alert OK button"),
                                                            style: .`default`,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            }
            
            reqsession.resume()
            
        } catch {
            print(error.localizedDescription)
            return
        }
    }
}

// MARK: - Privates

extension ViewController {
    fileprivate func setupScene() {
        targetImageView.isHidden = true
        sceneView.delegate = self
        sceneView.session = session
        loadingView.startAnimating()
        meterImageView.isHidden = true
        messageLabel.text = "Detecting the world…"
        resetButton.isHidden = true
        resetImageView.isHidden = true
        submitButton.isHidden = true
        undoButton.isHidden = true
        session.run(sessionConfiguration, options: [.resetTracking, .removeExistingAnchors])
        resetValues()
    }
    
    fileprivate func resetValues() {
        isMeasuring = false
        startValue = SCNVector3()
        endValue =  SCNVector3()
    }
    
    fileprivate func detectObjects() {
        guard let worldPosition = sceneView.realWorldVector(screenPosition: view.center) else { return }
        targetImageView.isHidden = false
        meterImageView.isHidden = false
        if lines.isEmpty {
            //messageLabel.text = "Hold screen & move your phone…"
        }
        loadingView.stopAnimating()
        if isMeasuring {
            if startValue == vectorZero {
                startValue = worldPosition
                currentLine = Line(sceneView: sceneView, startVector: startValue, unit: unit)
            }
            endValue = worldPosition
            currentLine?.update(to: endValue)
            messageLabel.text = currentLine?.distance(to: endValue) ?? "Calculating…"
        }
    }
}
