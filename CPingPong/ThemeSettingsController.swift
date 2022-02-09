//
//  ThemeSettingsController.swift
//  CPingPong
//
//  Created by 林子轩 on 2022/2/8.
//

import UIKit

class ThemeSettingsController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var themePicker: UIPickerView!
    @IBOutlet weak var ballPicker: UIPickerView!
    @IBOutlet weak var p1Picker: UIPickerView!
    @IBOutlet weak var p2Picker: UIPickerView!
    
    var themePickerData: [String] = [String]()
    var ballPickerData: [String] = [String]()
    var p1PickerData: [String] = [String]()
    var p2PickerData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.viewBackgroundColor()
        
        self.themePicker.delegate = self
        self.themePicker.dataSource = self
        
        self.ballPicker.delegate = self
        self.ballPicker.dataSource = self
        
        self.p1Picker.delegate = self
        self.p1Picker.dataSource = self
        
        self.p2Picker.delegate = self
        self.p2Picker.dataSource = self
        
        themePickerData = ["um", "uwm", "osu"]
        ballPickerData = ["yellow", "white"]
        p1PickerData = ["um", "uwm", "osu"]
        p2PickerData = ["um", "uwm", "osu"]
        
        themePicker.selectRow(themePickerData.firstIndex(of: UserDefaults.standard.string(forKey: "theme")!)!, inComponent: 0, animated: false)
        ballPicker.selectRow(ballPickerData.firstIndex(of: UserDefaults.standard.string(forKey: "ball")!)!, inComponent: 0, animated: false)
        p1Picker.selectRow(p1PickerData.firstIndex(of: UserDefaults.standard.string(forKey: "p1")!)!, inComponent: 0, animated: false)
        p2Picker.selectRow(p2PickerData.firstIndex(of: UserDefaults.standard.string(forKey: "p2")!)!, inComponent: 0, animated: false)
        
        
        // Do any additional setup after loading the view.
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case themePicker:
            return themePickerData.count
        case ballPicker:
            return ballPickerData.count
        case p1Picker:
            return p2PickerData.count
        case p2Picker:
            return p2PickerData.count
        default:
            exit(1)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case themePicker:
            return themePickerData[row]
        case ballPicker:
            return ballPickerData[row]
        case p1Picker:
            return p1PickerData[row]
        case p2Picker:
            return p2PickerData[row]
        default:
            exit(1)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case themePicker:
            UserDefaults.standard.setValue(themePickerData[row], forKey: "theme")
            self.view.backgroundColor = UIColor.viewBackgroundColor()
        case ballPicker:
            UserDefaults.standard.setValue(ballPickerData[row], forKey: "ball")
        case p1Picker:
            UserDefaults.standard.setValue(p1PickerData[row], forKey: "p1")
        case p2Picker:
            UserDefaults.standard.setValue(p2PickerData[row], forKey: "p2")
        default:
            exit(1)
        }
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

extension UIColor {
    class func viewBackgroundColor() -> UIColor {
        switch UserDefaults.standard.value(forKey: "theme") as! String {
        case "um":
            return UIColor(red: 236.0/255, green: 205.0/255, blue: 99.0/255, alpha: 1)
        case "uwm":
            return UIColor.white
        case "osu":
            return UIColor(red: 176.0/255, green: 183.0/255, blue: 188.0/255, alpha: 1)
        default:
            return UIColor.lightGray
        }
    }
    
    class func viewSecondaryColor() -> UIColor {
        switch UserDefaults.standard.value(forKey: "theme") as! String {
        case "um":
            return UIColor(red: 101.0/255, green: 23.0/255, blue: 201.0/255, alpha: 1)
        case "uwm":
            return UIColor.darkGray
        case "osu":
            return UIColor.orange
        default:
            return UIColor.lightGray
        }
    }
}
