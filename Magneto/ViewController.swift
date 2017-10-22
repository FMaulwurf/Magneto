import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    @IBOutlet weak var xValue: UILabel!
    @IBOutlet weak var yValue: UILabel!
    @IBOutlet weak var zValue: UILabel!
    @IBOutlet weak var recordedTimeLabel: UILabel!
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var AccuracyLabel: UILabel!
    
    let motionManager = CMMotionManager()
    let maxDisplayedValues: Double = 1.5
    let updateInterval: Double = 0.025
    let maxDisplayedLength: Int = 10
    let recordLength: Int = 10
    let CSV_DELIMITER: String = ";"
    let CSV_EOL: String = "\n"
    let dir = try? FileManager.default.url(for: .documentDirectory,
                                           in: .userDomainMask, appropriateFor: nil, create: true)
    var isRecording: Bool = false
    var startOfRecording: Date? = nil
    var firstTimestamp: Double? = nil
    var timer: Timer? = nil
    var recordedValues: [String] = []
    
    var mData: CMDeviceMotion = CMDeviceMotion() {
        didSet {
            AccuracyLabel.text = getAccuracy(mData.magneticField.accuracy)
            let field = mData.magneticField.field
            self.xValue.text = truncate(field.x, self.maxDisplayedLength)
            self.yValue.text = truncate(field.y, self.maxDisplayedLength)
            self.zValue.text = truncate(field.z, self.maxDisplayedLength)
            
            let x: Double = -field.x;
            let y: Double = field.y;
            let angle: Double = atan2(y, x);
            
            arrowImage.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
                        
            if (isRecording) {
                if (firstTimestamp == nil) {
                    firstTimestamp = mData.timestamp
                }
                let diff: Int = Int((mData.timestamp - firstTimestamp!) * 1000)
                if (diff >= 2000 && diff <= 8000) {
                    self.appendValuesToLog(time: String(diff), x: generateStringForLog(field.x), y: generateStringForLog(field.y), z: generateStringForLog(field.z))
                }
            }
        }
    }
    var file: URL? = nil {
        didSet {
            isRecording = file != nil
        }
    }
    
    func generateStringForLog(_ value:Double) -> String{
        return String(value).replacingOccurrences(of: ".", with: ",")
    }
    
    @IBAction func startRecording() {
        if (!isRecording) {
            startButton.isEnabled = false
            stopButton.isEnabled = true
            recordedTimeLabel.text = "0s"
            self.appendValuesToLog(time: "timestamp", x: "X", y: "Y", z: "Z")
            let filename = "output_" + String(getFormatedDateForFileName())
            if (dir != nil) {
                self.file = dir?.appendingPathComponent(filename).appendingPathExtension("csv")
            }
            startOfRecording = Date()
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.updateRecordedTime), userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func stopRecording() {
        recordStop()
    }
    
    func appendValuesToLog(time: String, x: String, y: String, z: String) {
        recordedValues.append(time + self.CSV_DELIMITER + x + self.CSV_DELIMITER + y + self.CSV_DELIMITER + z + self.CSV_EOL)
    }
    
    func writeToFile() {
        if (self.file != nil) {
            do {
                try recordedValues.joined().write(to: self.file!, atomically: true, encoding: .utf8)
            } catch {
                print("Failed writing to URL: \(String(describing: self.file!)), Error: " + error.localizedDescription)
            }
        }
    }
    
    func recordStop() {
        writeToFile()
        self.file = nil
        self.timer?.invalidate()
        recordedValues = []
        firstTimestamp = nil
        recordedTimeLabel.text = "0s"
        startButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionManager.showsDeviceMovementDisplay = true
        motionManager.deviceMotionUpdateInterval = self.updateInterval
        
        motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical, to: OperationQueue.main) { magnetoData, error in
            if (magnetoData != nil) {
                self.mData = magnetoData!
            }
        }
    }
    
    @objc func updateRecordedTime() {
        let diff: Int = Int(Date().timeIntervalSince(startOfRecording!))
        if (self.recordLength < diff) {
            recordStop()
        } else {
            recordedTimeLabel.text = String(diff) + "s"
        }
    }
    
}

func getAccuracy(_ acc: CMMagneticFieldCalibrationAccuracy) -> String {
    switch(acc) {
        case CMMagneticFieldCalibrationAccuracy.uncalibrated:
            return "uncalibrated"
        case CMMagneticFieldCalibrationAccuracy.low:
            return "low"
        case CMMagneticFieldCalibrationAccuracy.medium:
            return "medium"
        case CMMagneticFieldCalibrationAccuracy.high:
            return "high"
    }
}

func getFormatedDateForFileName() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HH-mm-ss"
    return formatter.string(from: Date())
}

func truncate(_ val: Double, _ length: Int) -> String {
    return String(format: "%." + String(length) + "f", val)
}

