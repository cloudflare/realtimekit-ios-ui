//
//  RtkCustomPickerView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 08/12/22.
//

import RealtimeKit
import UIKit

public protocol PickerCellModel {
    var name: String { get }
}

public protocol PickerModel {
    var title: String { get }
    var selectedIndex: UInt { get }
    associatedtype CellModel: PickerCellModel
    var cells: [CellModel] { get }
}

struct RtkAudioPickerCellModel: PickerCellModel {
    let name: String
    let deviceType: AudioDeviceType
}

struct CameraPickerCellModel: PickerCellModel {
    let name: String

    let deviceType: VideoDeviceType
}

struct RtkPickerModel<CellModel: PickerCellModel>: PickerModel {
    let title: String
    let selectedIndex: UInt
    let cells: [CellModel]
}

class RtkCustomPickerView<Model: PickerModel>: UIView, UIPickerViewDelegate, UIPickerViewDataSource {
    static func show(model: Model, on view: UIView) -> RtkCustomPickerView {
        let pickerView = RtkCustomPickerView(heading: model.title, list: model.cells, selectedIndex: model.selectedIndex)
        let baseView = pickerView.wrapperView()
        view.addSubview(baseView)
        baseView.set(.fillSuperView(view))
        pickerView.set(.sameLeadingTrailing(baseView),
                       .bottom(baseView))
        pickerView.baseView = baseView
        baseView.frame.origin.y = view.frame.height
        UIView.animate(withDuration: 0.3) {
            baseView.frame.origin.y = 0.0
        }
        return pickerView
    }

    var options: [Model.CellModel]
    private let title: String
    private var pickerView: UIPickerView!
    private var toolBar: UIToolbar!
    let heightPickerView: CGFloat = 250.0
    private var baseView: UIView?

    // private var onClick()
    private var selectedIndex: UInt = 0
    private var selectedOption: Model.CellModel?

    var onSelectRow: ((RtkCustomPickerView, Int) -> Void)?
    var onCancelButtonClick: ((RtkCustomPickerView) -> Void)?
    var onDoneButtonClick: ((RtkCustomPickerView) -> Void)?

    init(heading: String = "", list: [Model.CellModel], selectedIndex: UInt) {
        options = list
        if list.count > 0, selectedIndex >= list.count {
            self.selectedIndex = UInt(list.count - 1)
        } else {
            self.selectedIndex = selectedIndex
        }
        title = heading
        super.init(frame: .zero)
        setUpView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refresh(list: [Model.CellModel], selectedIndex: UInt) {
        options = list
        if list.count > 0, selectedIndex >= list.count {
            self.selectedIndex = UInt(list.count - 1)
        } else {
            self.selectedIndex = selectedIndex
        }
        pickerView.reloadAllComponents()
        pickerView.selectRow(Int(self.selectedIndex), inComponent: 0, animated: true)
    }

    private func setUpView() {
        createPickerView()
        createToolbar()
        toolBar.set(.sameLeadingTrailing(self),
                    .top(self))
        pickerView.set(.below(toolBar),
                       .sameLeadingTrailing(self),
                       .height(heightPickerView),
                       .bottom(self))
    }

    let colorToken = DesignLibrary.shared.color
    private func createPickerView() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.setValue(colorToken.textColor.onBackground.shade1000, forKey: "textColor")
        pickerView.backgroundColor = colorToken.background.shade900
        self.pickerView = pickerView
        pickerView.selectRow(Int(selectedIndex), inComponent: 0, animated: true)
        addSubview(pickerView)
    }

    private func createToolbar() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        toolBar.barTintColor = colorToken.background.shade700
        self.toolBar = toolBar
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonClick))
        doneButton.setTitleTextAttributes([.foregroundColor: colorToken.textColor.onBackground.shade1000], for: .normal)

        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonClick))
        cancelButton.setTitleTextAttributes([.foregroundColor: colorToken.textColor.onBackground.shade1000], for: .normal)

        toolBar.isUserInteractionEnabled = true
        let titleButton = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
        titleButton.isEnabled = false
        titleButton.setTitleTextAttributes([.foregroundColor: colorToken.textColor.onBackground.shade1000], for: .disabled)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([cancelButton, spaceButton, titleButton, spaceButton, doneButton], animated: true)
        addSubview(toolBar)
    }

    @objc func doneButtonClick() {
        removePickerView()
        onDoneButtonClick?(self)
    }

    private func removePickerView() {
        if let baseView {
            UIView.animate(withDuration: 0.3) {
                baseView.frame.origin.y = baseView.frame.height
            } completion: { _ in
                baseView.removeFromSuperview()
            }
        }
    }

    @objc func cancelButtonClick() {
        onCancelButtonClick?(self)
        DispatchQueue.main.async {
            self.removePickerView()
        }
    }

    func numberOfComponents(in _: UIPickerView) -> Int {
        1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        options.count
    }

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        options[row].name
    }

    func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        selectedOption = options[row]
        onSelectRow?(self, row)
    }
}
