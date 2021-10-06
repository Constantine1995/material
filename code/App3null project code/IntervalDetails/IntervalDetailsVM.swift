//
//  IntervalDetailsVM.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 30.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import CoreData
import UIKit

enum EyeType {
    case left
    case right

    var title: String {
        switch self {
        case .left:
            return Localizations.IntervalSchedules.intervalSchedules_left
        case .right:
            return Localizations.IntervalSchedules.intervalSchedules_right
        }
    }

    var color: UIColor {
        switch self {
        case .left:
            return .deepSkyBlue
        case .right:
            return .systemMagenta
        }
    }
}

// MARK: - Protocol

protocol IntervalDetailsVMProtocol {
    func numberOfRows() -> Int
    func item(at indexPath: IndexPath) -> IntervalDetailsItem
    func didSelectRow(at index: Int)
    func speakButtonPressed(indexPaths: [IndexPath])
    func setSpeechData(data: [SpeechData])
    func dismiss()
    var timeDelegate: TimeEntryDelegate? { get set }
    var medNameDelegate: MedNameEntryDelegate? { get set }
    var tableViewDelegate: TableViewDelegate? { get set }
    var interval: Interval { get }
}

class IntervalDetailsVM: NSObject, MVVMViewModel {

    let router: MVVMRouter
    let dataManager: DataManagerProtocol
    let interval: Interval

    weak var timeDelegate: TimeEntryDelegate?
    weak var medNameDelegate: MedNameEntryDelegate?
    weak var tableViewDelegate: TableViewDelegate?

    private var dataSource: [IntervalDetailsItem] = IntervalDetailsItem.allCases
    var speechData = [SpeechData]()
    lazy var speechSynthesizer: SpeechSynthesizerInterface = {
        SpeechSynthesizer(delegate: self)
    }()

    //==============================================================================

    init(with router: MVVMRouter, dataManager: DataManagerProtocol, interval: Interval) {
        self.router = router
        self.interval = interval
        self.dataManager = dataManager
        super.init()
        timeDelegate = self
        medNameDelegate = self
    }

    //==============================================================================
}

extension IntervalDetailsVM: IntervalDetailsVMProtocol {

    func numberOfRows() -> Int {
        return dataSource.count
    }

    func item(at indexPath: IndexPath) -> IntervalDetailsItem {
        return dataSource[indexPath.row]
    }

    func didSelectRow(at index: Int) {
        speechSynthesizer.stopSpeaking()
        switch dataSource[index] {
        case .time:
            router.enqueueRoute(with: IntervalDetailsRouter.RouteType.showTimeEntry(interval: interval, delegate: timeDelegate))
        case .left:
            let medName = interval.leftEyeDrugName ?? ""
            showMedNameEntry(medName: medName, type: .left)
        case .right:
            let medName = interval.rightEyeDrugName ?? ""
            showMedNameEntry(medName: medName, type: .right)
        }
    }

    func speakButtonPressed(indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let data = createSpeechData(indexPath: indexPath)
            speechData.append(data)
            setSpeechData(data: speechData)
        }
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking()
        } else {
            speechSynthesizer.startSpeaking()
        }
    }

    func dismiss() {
        speechSynthesizer.stopSpeaking()
        router.dismiss(animated: false, context: nil, completion: nil)
    }

    private func showMedNameEntry(medName: String, type: EyeType) {
        let data = MedNameData(medName: medName, time: interval.title, type: type)
        router.enqueueRoute(with: IntervalDetailsRouter.RouteType.showMedicationEntry(data: data, delegate: medNameDelegate))
    }

    func setSpeechData(data: [SpeechData]) {
        speechSynthesizer.setSpeechData(data: data)
    }

    private func createSpeechData(indexPath: IndexPath) -> SpeechData {
        let placeholder = StatusMessage.placeholder.localizedDescription

        let date = interval.date?.toString(format: .time) ?? ""
        let leftEyeDrugName = interval.leftEyeDrugName ?? placeholder
        let rightEyeDrugName = interval.rightEyeDrugName ?? placeholder

        let titles = dataSource[indexPath.row].title
        let text = [date, leftEyeDrugName, rightEyeDrugName]
        let speechText = "\(titles) \(text[indexPath.row])"

        return SpeechData(text: "\(speechText)", indexPath: indexPath)
    }
}

extension IntervalDetailsVM: TimeEntryDelegate {
    func datePickerDidSelectTime(_ time: Int) {
        dataManager.updateTime(for: interval, time: time)
    }
}

extension IntervalDetailsVM: MedNameEntryDelegate {
    func notePickerDidChange(_ name: String, type: EyeType) {
        dataManager.updateDrugName(for: interval, name: name, eye: type)
    }
}

// MARK: - SpeechSynthesizerDelegate

extension IntervalDetailsVM: SpeechSynthesizerDelegate {
    func speechStarted(for speechData: SpeechData) {
        tableViewDelegate?.setHighlightCell(for: speechData, highlight: true)
    }

    func speechEnded(for speechData: SpeechData) {
        tableViewDelegate?.setHighlightCell(for: speechData, highlight: false)
        self.speechData.removeAll()
    }

    func speechFinished() {
        tableViewDelegate?.scrollToTop()
    }
}
