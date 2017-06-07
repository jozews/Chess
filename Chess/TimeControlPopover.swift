//
//  SetTimePopover.swift
//  Chess
//
//  Created by Jože Ws on 11/4/15.
//  Copyright © 2015 Self. All rights reserved.
//

import UIKit

struct TimeControl {
    
    let initial: Double
    let bonus: Double
    
    var title: String {
        let mins = initial/6
        return "\(mins) + min\(mins > 1 ? "s" :  "") + \(bonus)"
    }
    
    init(initial: Double, bonus: Double) {
        self.initial = initial
        self.bonus = bonus
    }

}

class TimeControlPopover: UIViewController, UIPickerViewDataSource,UIPopoverPresentationControllerDelegate {

    var timePicker: UIPickerView!
    
    let selectIndex: Int
    let numberOfComponents: Int
    
    init(selectIndex: Int, numberOfComponents: Int) {
        self.selectIndex = selectIndex
        self.numberOfComponents = numberOfComponents
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        popoverPresentationController!.delegate = self
        popoverPresentationController!.passthroughViews = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        timePicker = UIPickerView(frame: view.frame)
        timePicker!.dataSource = self
        view.addSubview(timePicker!)
        timePicker!.selectRow(selectIndex, inComponent: 0, animated: true)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfComponents
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
    
}



